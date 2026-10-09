import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/features/export/data/pdf_builder.dart';
import 'package:banglascanner/features/export/data/pdf_encryption.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Uint8List _hex(String s) => Uint8List.fromList([for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)]);

String _toHex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('Aes128Cbc', () {
    test('matches the FIPS-197 known answer', () {
      final block = _hex('00112233445566778899aabbccddeeff');
      Aes128Cbc(_hex('000102030405060708090a0b0c0d0e0f')).encryptBlock(block);
      expect(_toHex(block), '69c4e0d86a7b0430d8cdb78070b4c55a');
    });

    test('CBC chains blocks, pads with PKCS#5 and prepends the IV', () {
      // NIST SP 800-38A F.2.1 CBC-AES128.Encrypt, first two blocks.
      final key = _hex('2b7e151628aed2a6abf7158809cf4f3c');
      final iv = _hex('000102030405060708090a0b0c0d0e0f');
      final plain = _hex('6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e51');
      final out = Aes128Cbc(key).encrypt(plain, iv);
      expect(out.length, 16 + 32 + 16, reason: 'IV + data + a full padding block');
      expect(_toHex(out.sublist(0, 16)), _toHex(iv));
      expect(_toHex(out.sublist(16, 48)), '7649abac8119b246cee98e9b12e9197d5086cb9b507219ee95db113a917678b2');
    });
  });

  test('Rc4 matches a known vector', () {
    // Wikipedia test vector: Key "Key", plaintext "Plaintext".
    final out = Rc4(Uint8List.fromList(utf8.encode('Key'))).process(Uint8List.fromList(utf8.encode('Plaintext')));
    expect(_toHex(out), 'bbf316e8d940af0ad3');
  });

  group('PdfBuilder', () {
    test('writes an /Encrypt dictionary when a password is given', () async {
      final pdf = await PdfBuilder.build([fakeDocumentJpeg(width: 100, height: 140)], password: 'secret');
      final text = latin1.decode(pdf);
      expect(text, contains('/Encrypt'));
      expect(text, contains('/AESV2'));
      expect(text, contains('/Filter/Standard'));
      // Plain-text metadata must not leak.
      expect(text, isNot(contains('Bangla Scanner')));

      final plain = await PdfBuilder.build([fakeDocumentJpeg(width: 100, height: 140)]);
      expect(latin1.decode(plain), isNot(contains('/Encrypt')));
      expect(latin1.decode(plain), contains('Bangla Scanner'));

      // Keep a copy for an external check with a PDF reader when wanted.
      final out = Platform.environment['PDF_OUT'];
      if (out != null) File(out).writeAsBytesSync(pdf);
    });

    test('fixed page sizes fit the scan on real paper', () async {
      final landscape = fakeDocumentJpeg(width: 140, height: 100);
      final pdf = await PdfBuilder.build([landscape], pageSize: PdfPageSize.a4);
      final text = latin1.decode(pdf);
      // A4 landscape MediaBox is 841.89 × 595.28 pt.
      expect(text, contains('/MediaBox[0 0 841.88976'));
    });
  });
}
