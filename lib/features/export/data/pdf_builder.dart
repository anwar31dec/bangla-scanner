import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/enums.dart';
import 'pdf_encryption.dart';

/// Builds PDFs from page images. Pure Dart, safe to run in an isolate.
class PdfBuilder {
  PdfBuilder._();

  /// Margin around the scan on a fixed-size page.
  static const fixedPageMarginMm = 8.0;

  /// One page per JPEG. With [PdfPageSize.auto] each page is shaped like
  /// its image so any paper size (A4, Legal, a receipt, a card) fills the
  /// page with no blank bands; a fixed [pageSize] fits the scan inside a
  /// real paper size instead (turned landscape for a landscape scan).
  ///
  /// With a [password] the file is AES-128 encrypted and opens only with
  /// that password.
  static Future<Uint8List> build(
    List<Uint8List> jpegPages, {
    String? title,
    PdfPageSize pageSize = PdfPageSize.auto,
    String? password,
  }) async {
    final doc = pw.Document(title: title, creator: 'Bangla Scanner', producer: 'Bangla Scanner');
    if (password != null && password.isNotEmpty) {
      doc.document.encryption = PdfStandardEncryption(doc.document, userPassword: password);
    }
    for (final bytes in jpegPages) {
      final image = pw.MemoryImage(bytes);
      final w = image.width ?? 1, h = image.height ?? 1;
      if (pageSize.isFixed) {
        final paper = PdfPageFormat(pageSize.widthMm * PdfPageFormat.mm, pageSize.heightMm * PdfPageFormat.mm);
        doc.addPage(
          pw.Page(
            pageFormat: w > h ? paper.landscape : paper.portrait,
            margin: const pw.EdgeInsets.all(fixedPageMarginMm * PdfPageFormat.mm),
            build: (context) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
          ),
        );
      } else {
        doc.addPage(
          pw.Page(
            pageFormat: pageFormatFor(w, h),
            margin: pw.EdgeInsets.zero,
            build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
          ),
        );
      }
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
