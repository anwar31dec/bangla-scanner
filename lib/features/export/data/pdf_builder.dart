import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds PDFs from page images. Pure Dart, safe to run in an isolate.
class PdfBuilder {
  PdfBuilder._();

  /// One A4 page per JPEG, each image scaled to fit and centred. Pages keep
  /// their orientation: landscape images get a landscape A4 page.
  static Future<Uint8List> build(List<Uint8List> jpegPages, {String? title}) async {
    final doc = pw.Document(title: title, creator: 'Bangla Scanner', producer: 'Bangla Scanner');
    for (final bytes in jpegPages) {
      final image = pw.MemoryImage(bytes);
      final landscape = (image.width ?? 1) > (image.height ?? 1);
      doc.addPage(
        pw.Page(
          pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }
    return doc.save();
  }
}
