import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds PDFs from page images. Pure Dart, safe to run in an isolate.
class PdfBuilder {
  PdfBuilder._();

  /// One page per JPEG, each page shaped like its image so any paper size
  /// (A4, Legal, a receipt, a card) fills the page with no blank bands.
  static Future<Uint8List> build(List<Uint8List> jpegPages, {String? title}) async {
    final doc = pw.Document(title: title, creator: 'Bangla Scanner', producer: 'Bangla Scanner');
    for (final bytes in jpegPages) {
      final image = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: pageFormatFor(image.width ?? 1, image.height ?? 1),
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }
    return doc.save();
  }

  /// Page with the aspect ratio of a [width] × [height] image. A scan carries
  /// no physical size, so the short side is given the width of A4: an A4 scan
  /// comes out as A4 and longer paper (Legal) just gets a longer page.
  static PdfPageFormat pageFormatFor(int width, int height) {
    final short = PdfPageFormat.a4.width;
    if (width <= 0 || height <= 0) return PdfPageFormat.a4;
    // PDF pages may be at most 200 inches long.
    const maxLong = 200 * PdfPageFormat.inch;
    return width > height
        ? PdfPageFormat(math.min(short * width / height, maxLong), short)
        : PdfPageFormat(short, math.min(short * height / width, maxLong));
  }
}
