// The pdf package exposes the PdfEncryption hook but keeps the object model
// it is built with (dictionaries, strings, object references) in its
// implementation files.
// ignore_for_file: implementation_imports

import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show md5;
import 'package:pdf/pdf.dart';
import 'package:pdf/src/pdf/format/dict.dart';
import 'package:pdf/src/pdf/format/num.dart';
import 'package:pdf/src/pdf/format/object_base.dart';
import 'package:pdf/src/pdf/format/string.dart';

/// The PDF "standard security handler" with AES-128 (PDF 1.6, revision 4):
/// the document opens only with [userPassword]. Every string and stream is
/// encrypted; metadata as well.
///
/// The owner password lets a reader change permissions; a random one is
/// used when none is given, so only the user password matters.
class PdfStandardEncryption extends PdfEncryption {
  PdfStandardEncryption(super.pdfDocument, {required String userPassword, String? ownerPassword})
      : _user = _passwordBytes(userPassword),
        _owner = _passwordBytes(ownerPassword ?? _randomPassword()) {
    _o = _computeO(_owner, _user);
    _key = _computeKey(_user, _o, pdfDocument.documentID);
    _u = _computeU(_key, pdfDocument.documentID);
  }

  /// Every permission allowed; bits 1 and 2 are reserved and must be 0.
  static const _permissions = -4;

  static const _keyLength = 16;

  /// Padding string from the PDF specification (algorithm 2, step 1).
  static final _pad = Uint8List.fromList(const [
    0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41, 0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08, //
    0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80, 0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A,
  ]);

  final Uint8List _user;
  final Uint8List _owner;
  late final Uint8List _o;
  late final Uint8List _u;
  late final Uint8List _key;

  static final _random = Random.secure();

  @override
  void prepare() {
    super.prepare();
    params['/Filter'] = const PdfName('/Standard');
    params['/V'] = const PdfNum(4);
    params['/R'] = const PdfNum(4);
    params['/Length'] = const PdfNum(_keyLength * 8);
    params['/P'] = const PdfNum(_permissions);
    params['/CF'] = PdfDict({
      '/StdCF': PdfDict({
        '/CFM': const PdfName('/AESV2'),
        '/AuthEvent': const PdfName('/DocOpen'),
        '/Length': const PdfNum(_keyLength),
      }),
    });
    params['/StmF'] = const PdfName('/StdCF');
    params['/StrF'] = const PdfName('/StdCF');
    params['/O'] = PdfString(_o, format: PdfStringFormat.binary, encrypted: false);
    params['/U'] = PdfString(_u, format: PdfStringFormat.binary, encrypted: false);
  }

  /// AES-128-CBC with a random IV in front (algorithm 1 of the spec).
  @override
  Uint8List encrypt(Uint8List input, PdfObjectBase object) {
    final objectKey = _objectKey(object.objser, object.objgen);
    final iv = Uint8List(16);
    for (var i = 0; i < iv.length; i++) {
      iv[i] = _random.nextInt(256);
    }
    return Aes128Cbc(objectKey).encrypt(input, iv);
  }

  Uint8List _objectKey(int objser, int objgen) {
    final input = Uint8List(_key.length + 5 + 4)
      ..setAll(0, _key)
      ..[_key.length] = objser & 0xFF
      ..[_key.length + 1] = (objser >> 8) & 0xFF
      ..[_key.length + 2] = (objser >> 16) & 0xFF
      ..[_key.length + 3] = objgen & 0xFF
      ..[_key.length + 4] = (objgen >> 8) & 0xFF
      // "sAlT", required for AES.
      ..[_key.length + 5] = 0x73
      ..[_key.length + 6] = 0x41
      ..[_key.length + 7] = 0x6C
      ..[_key.length + 8] = 0x54;
    final digest = _md5(input);
    return Uint8List.sublistView(digest, 0, min(_key.length + 5, 16));
  }

  // Algorithm 2: encryption key from the user password.
  static Uint8List _computeKey(Uint8List user, Uint8List o, Uint8List fileId) {
    final builder = BytesBuilder(copy: false)
      ..add(_padded(user))
      ..add(o)
      ..add(_int32LittleEndian(_permissions))
      ..add(fileId);
    var hash = _md5(builder.toBytes());
    for (var i = 0; i < 50; i++) {
      hash = _md5(Uint8List.sublistView(hash, 0, _keyLength));
    }
    return Uint8List.sublistView(hash, 0, _keyLength);
  }

  // Algorithm 3: the /O entry.
  static Uint8List _computeO(Uint8List owner, Uint8List user) {
    var hash = _md5(_padded(owner));
    for (var i = 0; i < 50; i++) {
      hash = _md5(hash);
    }
    final key = Uint8List.sublistView(hash, 0, _keyLength);
    return _rc4Rounds(key, _padded(user));
  }

  // Algorithm 5: the /U entry (revision 3 and later).
  static Uint8List _computeU(Uint8List key, Uint8List fileId) {
    final hash = _md5(Uint8List.fromList([..._pad, ...fileId]));
    final out = Uint8List(32)..setAll(0, _rc4Rounds(key, hash));
    // The last 16 bytes are arbitrary padding.
    for (var i = 16; i < 32; i++) {
      out[i] = _pad[i];
    }
    return out;
  }

  /// RC4 with [key], then 19 more passes with every key byte XORed with the
  /// pass number (shared by algorithms 3 and 5).
  static Uint8List _rc4Rounds(Uint8List key, Uint8List data) {
    var out = Rc4(key).process(data);
    final roundKey = Uint8List(key.length);
    for (var i = 1; i <= 19; i++) {
      for (var k = 0; k < key.length; k++) {
        roundKey[k] = key[k] ^ i;
      }
      out = Rc4(roundKey).process(out);
    }
    return out;
  }

  static Uint8List _padded(Uint8List password) {
    final out = Uint8List(32);
    final n = min(32, password.length);
    out.setRange(0, n, password);
    out.setRange(n, 32, _pad);
    return out;
  }

  /// Passwords are Latin-1 in this revision; other characters are reduced
  /// to their low byte, which is what common readers do as well.
  static Uint8List _passwordBytes(String password) =>
      Uint8List.fromList([for (final c in password.codeUnits) c & 0xFF]);

  static String _randomPassword() => String.fromCharCodes(List.generate(32, (_) => 33 + _random.nextInt(94)));

  static Uint8List _int32LittleEndian(int value) =>
      Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);

  static Uint8List _md5(List<int> data) => Uint8List.fromList(md5.convert(data).bytes);
}

/// RC4 stream cipher (only used for the password hashes in the PDF header,
/// as the specification requires).
class Rc4 {
  Rc4(Uint8List key) {
    for (var i = 0; i < 256; i++) {
      _s[i] = i;
    }
    var j = 0;
    for (var i = 0; i < 256; i++) {
      j = (j + _s[i] + key[i % key.length]) & 0xFF;
      final t = _s[i];
      _s[i] = _s[j];
      _s[j] = t;
    }
  }

  final _s = Uint8List(256);

  Uint8List process(Uint8List data) {
    final out = Uint8List(data.length);
    var i = 0, j = 0;
    for (var n = 0; n < data.length; n++) {
      i = (i + 1) & 0xFF;
      j = (j + _s[i]) & 0xFF;
      final t = _s[i];
      _s[i] = _s[j];
      _s[j] = t;
      out[n] = data[n] ^ _s[(_s[i] + _s[j]) & 0xFF];
    }
    return out;
  }
}

/// AES-128 in CBC mode with PKCS#5 padding; the IV is written in front of
/// the ciphertext as PDF requires. Encryption only.
class Aes128Cbc {
  Aes128Cbc(Uint8List key) : _roundKeys = _expandKey(key) {
    if (key.length != 16) throw ArgumentError('AES-128 needs a 16 byte key');
  }

  static const _rounds = 10;

  final Uint8List _roundKeys;

  Uint8List encrypt(Uint8List input, Uint8List iv) {
    if (iv.length != 16) throw ArgumentError('IV must be 16 bytes');
    final padLength = 16 - input.length % 16;
    final padded = Uint8List(input.length + padLength)
      ..setAll(0, input)
      ..fillRange(input.length, input.length + padLength, padLength);
    final out = Uint8List(16 + padded.length)..setAll(0, iv);
    final block = Uint8List(16);
    var previous = iv;
    for (var offset = 0; offset < padded.length; offset += 16) {
      for (var i = 0; i < 16; i++) {
        block[i] = padded[offset + i] ^ previous[i];
      }
      encryptBlock(block);
      out.setRange(16 + offset, 32 + offset, block);
      previous = Uint8List.sublistView(out, 16 + offset, 32 + offset);
    }
    return out;
  }

  /// Encrypts one 16 byte [state] in place.
  void encryptBlock(Uint8List state) {
    _addRoundKey(state, 0);
    for (var round = 1; round < _rounds; round++) {
      _subBytes(state);
      _shiftRows(state);
      _mixColumns(state);
      _addRoundKey(state, round);
    }
    _subBytes(state);
    _shiftRows(state);
    _addRoundKey(state, _rounds);
  }

  void _addRoundKey(Uint8List s, int round) {
    final o = round * 16;
    for (var i = 0; i < 16; i++) {
      s[i] ^= _roundKeys[o + i];
    }
  }

  static void _subBytes(Uint8List s) {
    for (var i = 0; i < 16; i++) {
      s[i] = _sbox[s[i]];
    }
  }

  // State is column-major: byte i sits in row i % 4, column i ~/ 4.
  static void _shiftRows(Uint8List s) {
    var t = s[1];
    s[1] = s[5];
    s[5] = s[9];
    s[9] = s[13];
    s[13] = t;
    t = s[2];
    s[2] = s[10];
    s[10] = t;
    t = s[6];
    s[6] = s[14];
    s[14] = t;
    t = s[15];
    s[15] = s[11];
    s[11] = s[7];
    s[7] = s[3];
    s[3] = t;
  }

  static int _xtime(int b) => ((b << 1) ^ ((b & 0x80) != 0 ? 0x1B : 0)) & 0xFF;

  static void _mixColumns(Uint8List s) {
    for (var c = 0; c < 4; c++) {
      final o = c * 4;
      final a0 = s[o], a1 = s[o + 1], a2 = s[o + 2], a3 = s[o + 3];
      final all = a0 ^ a1 ^ a2 ^ a3;
      s[o] = a0 ^ all ^ _xtime(a0 ^ a1);
      s[o + 1] = a1 ^ all ^ _xtime(a1 ^ a2);
      s[o + 2] = a2 ^ all ^ _xtime(a2 ^ a3);
      s[o + 3] = a3 ^ all ^ _xtime(a3 ^ a0);
    }
  }

  static Uint8List _expandKey(Uint8List key) {
    final w = Uint8List(16 * (_rounds + 1))..setAll(0, key);
    var rcon = 1;
    for (var i = 16; i < w.length; i += 4) {
      var t0 = w[i - 4], t1 = w[i - 3], t2 = w[i - 2], t3 = w[i - 1];
      if (i % 16 == 0) {
        // RotWord, SubWord, Rcon.
        final tmp = t0;
        t0 = _sbox[t1] ^ rcon;
        t1 = _sbox[t2];
        t2 = _sbox[t3];
        t3 = _sbox[tmp];
        rcon = _xtime(rcon);
      }
      w[i] = w[i - 16] ^ t0;
      w[i + 1] = w[i - 15] ^ t1;
      w[i + 2] = w[i - 14] ^ t2;
      w[i + 3] = w[i - 13] ^ t3;
    }
    return w;
  }

  static const _sbox = [
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76, //
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
  ];
}
