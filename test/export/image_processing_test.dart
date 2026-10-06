import 'dart:typed_data';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/utils/app_exception.dart';
import 'package:banglascanner/features/export/data/image_processing.dart';
import 'package:banglascanner/features/export/data/pdf_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers.dart';

void main() {
  group('ImageProcessing', () {
    test('corrupt data throws a corruptFile AppException', () {
      expect(
        () => ImageProcessing.decode(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.corruptFile)),
      );
    });

    test('rotation swaps width and height', () {
      final src = img.Image(width: 40, height: 20);
      final r = ImageProcessing.rotateQuarterTurns(src, 1);
      expect([r.width, r.height], [20, 40]);
      expect(ImageProcessing.rotateQuarterTurns(src, 4).width, 40);
    });

    test('limitSize never upscales and keeps aspect ratio', () {
      final src = img.Image(width: 4000, height: 2000);
      final r = ImageProcessing.limitSize(src, 1000);
      expect([r.width, r.height], [1000, 500]);
      expect(ImageProcessing.limitSize(img.Image(width: 10, height: 10), 1000).width, 10);
    });

    test('black & white output contains only black and white pixels', () {
      final bw = ImageProcessing.applyFilter(ImageProcessing.decode(fakeDocumentJpeg()), PageFilter.blackWhite);
      final values = <num>{};
      for (final p in bw) {
        values.add(p.r);
      }
      expect(values.difference({0, 255}), isEmpty);
      expect(values, containsAll(<num>[0, 255]));
    });

    test('grayscale output has equal channels', () {
      final g = ImageProcessing.applyFilter(ImageProcessing.decode(fakeDocumentJpeg()), PageFilter.grayscale);
      final p = g.getPixel(100, 100);
      expect(p.r, p.g);
      expect(p.g, p.b);
    });

    test('processPage respects quality size limit and returns JPEG', () {
      final big = img.encodeJpg(img.Image(width: 5000, height: 3000), quality: 80);
      final out = ImageProcessing.processPage(big, quarterTurns: 1, filter: PageFilter.enhanced, quality: ExportQuality.low);
      final decoded = img.decodeJpg(out)!;
      expect(decoded.height, ExportQuality.low.maxEdge); // rotated: long edge is now height
      expect(decoded.width < decoded.height, isTrue);
    });
  });

  group('PdfBuilder', () {
    test('creates one A4 page per image', () async {
      final page = ImageProcessing.processPage(
        fakeDocumentJpeg(),
        quarterTurns: 0,
        filter: PageFilter.blackWhite,
        quality: ExportQuality.medium,
      );
      final pdf = await PdfBuilder.build([page, page, page], title: 'Test');
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      final text = String.fromCharCodes(pdf);
      expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 3);
      // A4 portrait in points.
      expect(text, contains('595.27'));
    });
  });
}
