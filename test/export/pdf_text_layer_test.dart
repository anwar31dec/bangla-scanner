import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/features/export/data/pdf_builder.dart';
import 'package:banglascanner/features/ocr/data/ocr_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Every Flate stream of the PDF, inflated and joined (content streams,
/// CMaps, …). Streams that are not Flate (images) are skipped.
String inflatedStreams(Uint8List pdf) {
  final text = latin1.decode(pdf);
  final out = StringBuffer();
  var from = 0;
  while (true) {
    final start = text.indexOf('stream\n', from);
    if (start < 0) break;
    final end = text.indexOf('endstream', start);
    if (end < 0) break;
    final body = pdf.sublist(start + 'stream\n'.length, end);
    try {
      out.writeln(latin1.decode(zlib.decode(body)));
    } catch (_) {}
    from = end + 'endstream'.length;
  }
  return out.toString();
}

void main() {
  final font = File(TextLayerFont.asset).readAsBytesSync();
  const page = PageText(
    text: 'আমার সোনার বাংলা\nTotal 250',
    words: [
      OcrWord('আমার', left: 0.10, top: 0.10, right: 0.25, bottom: 0.14),
      OcrWord('সোনার', left: 0.27, top: 0.10, right: 0.45, bottom: 0.14),
      OcrWord('Total', left: 0.10, top: 0.20, right: 0.20, bottom: 0.23),
    ],
  );

  test('words are drawn invisibly over the scan, mapped back to Unicode', () async {
    final pdf = await PdfBuilder.build([fakeDocumentJpeg()], title: 'T', texts: [page], fontData: font);
    final raw = latin1.decode(pdf);
    expect(raw, contains('/ToUnicode'), reason: 'the embedded font maps glyphs to Unicode');
    expect(raw, contains('/FontFile2'), reason: 'the TrueType font is embedded');

    final streams = inflatedStreams(pdf);
    // Rendering mode 3 = invisible, Tz = horizontal scaling to the box width.
    expect(RegExp(r'\b3 Tr\b').allMatches(streams).length, 3);
    expect(streams, contains(' Tz'));
    // The CMap carries the Bangla code points (U+0986 = আ).
    expect(streams.toLowerCase(), contains('0986'));
  });

  test('pages without words get no text layer and the font is not embedded', () async {
    final pdf = await PdfBuilder.build(
      [fakeDocumentJpeg(), fakeDocumentJpeg()],
      texts: [null, const PageText(text: 'only text, no boxes')],
      fontData: font,
    );
    final raw = latin1.decode(pdf);
    expect(raw, isNot(contains('/FontFile2')));
    expect(inflatedStreams(pdf), isNot(contains('3 Tr')));
  });

  test('the text layer follows the scan on a fixed paper size', () async {
    final pdf = await PdfBuilder.build([fakeDocumentJpeg()], pageSize: PdfPageSize.a4, texts: [page], fontData: font);
    final streams = inflatedStreams(pdf);
    expect(RegExp(r'\b3 Tr\b').allMatches(streams).length, 3);
    final plain = await PdfBuilder.build([fakeDocumentJpeg()], pageSize: PdfPageSize.a4);
    // Same page: the image is placed the same way with or without text.
    final mediaBox = RegExp(r'/MediaBox\s*\[0 0 595\.\d+ 841\.\d+\]');
    expect(latin1.decode(plain), contains(mediaBox));
    expect(latin1.decode(pdf), contains(mediaBox));
  });

  test('encrypted PDFs keep their text layer', () async {
    final pdf = await PdfBuilder.build([fakeDocumentJpeg()], password: 'pw', texts: [page], fontData: font);
    final raw = latin1.decode(pdf);
    expect(raw, contains('/Encrypt'));
    expect(raw, contains('/FontFile2'));
  });
}
