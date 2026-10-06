import 'dart:typed_data';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/utils/app_exception.dart';
import 'package:banglascanner/features/export/data/image_processing.dart';
import 'package:banglascanner/features/export/data/pdf_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';

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
        values.addAll([p.r, p.g, p.b]);
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

    test('black & white pages are saved without a colour cast', () {
      final jpeg = ImageProcessing.processPage(
        fakeDocumentJpeg(),
        quarterTurns: 0,
        filter: PageFilter.blackWhite,
        quality: ExportQuality.high,
      );
      final paper = img.decodeJpg(jpeg)!.getPixel(300, 30);
      expect([paper.r, paper.g, paper.b], everyElement(greaterThan(240)));
    });

    test('auto color removes the shadow: paper turns white, text stays dark', () {
      final out = ImageProcessing.applyFilter(ImageProcessing.decode(fakeDocumentJpeg()), PageFilter.autoColor);
      // From the lit side into the shadow (30% darker). Further right the
      // fixture's text underflows and is no longer dark.
      for (final x in [60, 250, 440]) {
        final paper = out.getPixel(x, 30), text = out.getPixel(x, 3);
        expect([paper.r, paper.g, paper.b], everyElement(greaterThan(245)), reason: 'paper at x=$x');
        expect(text.r, lessThan(100), reason: 'text at x=$x');
      }
    });

    test('every filter keeps the page size', () {
      final src = ImageProcessing.decode(fakeDocumentJpeg(width: 90, height: 70));
      for (final f in PageFilter.values) {
        final out = ImageProcessing.applyFilter(src, f);
        expect([out.width, out.height], [90, 70], reason: f.name);
      }
    });

    test('processPage respects quality size limit and returns JPEG', () {
      final big = img.encodeJpg(img.Image(width: 5000, height: 3000), quality: 80);
      final out = ImageProcessing.processPage(big, quarterTurns: 1, filter: PageFilter.autoColor, quality: ExportQuality.low);
      final decoded = img.decodeJpg(out)!;
      expect(decoded.height, ExportQuality.low.maxEdge); // rotated: long edge is now height
      expect(decoded.width < decoded.height, isTrue);
    });
  });

  group('PdfBuilder', () {
    test('creates one page per image', () async {
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
      // A4 width in points; the 600 × 800 image makes the page 4:3.
      expect(text, contains('595.27'));
      expect(text, contains('793.7'));
    });

    test('pages take the shape of the scan', () {
      const a4 = PdfPageFormat.a4;
      // A4 at 300 dpi stays A4.
      final portrait = PdfBuilder.pageFormatFor(2480, 3508);
      expect(portrait.width, a4.width);
      expect(portrait.height, closeTo(a4.height, 0.5));
      // Legal paper: same width, longer page.
      final legal = PdfBuilder.pageFormatFor(2199, 3508);
      expect(legal.width, a4.width);
      expect(legal.height / legal.width, closeTo(3508 / 2199, 1e-9));
      // Landscape keeps the short side on the height.
      final landscape = PdfBuilder.pageFormatFor(3508, 2199);
      expect(landscape.height, a4.width);
      expect(landscape.width, closeTo(legal.height, 1e-9));
    });
  });
}
