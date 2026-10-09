import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/enums.dart';
import '../../ocr/data/ocr_result.dart';
import 'pdf_encryption.dart';

/// Loads the TrueType font used for the invisible text layer.
typedef TextLayerFontLoader = Future<Uint8List> Function();

/// The font embedded (subset) in searchable PDFs. It must cover Bangla and
/// Latin: a PDF text layer maps glyphs back to Unicode through the font,
/// so a font without the characters would make the text unsearchable.
class TextLayerFont {
  TextLayerFont._();

  static const asset = 'assets/fonts/HindSiliguri-Regular.ttf';

  static Future<Uint8List>? _cached;

  /// Reads the font from the app bundle once.
  static Future<Uint8List> load() => _cached ??= rootBundle.load(asset).then((d) => d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes));
}

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
  ///
  /// With [texts] (one entry per page, null for pages without OCR) and the
  /// TrueType [fontData], every recognized word is drawn invisibly over its
  /// place on the scan, so the PDF can be searched, and its text selected
  /// and copied, in any PDF viewer.
  static Future<Uint8List> build(
    List<Uint8List> jpegPages, {
    String? title,
    PdfPageSize pageSize = PdfPageSize.auto,
    String? password,
    List<PageText?>? texts,
    Uint8List? fontData,
  }) async {
    final doc = pw.Document(title: title, creator: 'Bangla Scanner', producer: 'Bangla Scanner');
    if (password != null && password.isNotEmpty) {
      doc.document.encryption = PdfStandardEncryption(doc.document, userPassword: password);
    }
    final hasWords = texts != null && texts.any((t) => t != null && t.words.isNotEmpty);
    final font = hasWords && fontData != null ? PdfTtfFont(doc.document, ByteData.sublistView(fontData)) : null;

    for (var i = 0; i < jpegPages.length; i++) {
      final image = pw.MemoryImage(jpegPages[i]);
      final w = image.width ?? 1, h = image.height ?? 1;
      final text = font == null || texts == null || i >= texts.length ? null : texts[i];
      // The scan, with the text layer painted on top of it.
      pw.Widget scan = pw.Image(image, fit: pw.BoxFit.fill);
      if (text != null && text.words.isNotEmpty) {
        scan = pw.CustomPaint(
          foregroundPainter: (canvas, size) => drawTextLayer(canvas, size, font!, text),
          child: scan,
        );
      }
      if (pageSize.isFixed) {
        final paper = PdfPageFormat(pageSize.widthMm * PdfPageFormat.mm, pageSize.heightMm * PdfPageFormat.mm);
        doc.addPage(
          pw.Page(
            pageFormat: w > h ? paper.landscape : paper.portrait,
            margin: const pw.EdgeInsets.all(fixedPageMarginMm * PdfPageFormat.mm),
            build: (context) => pw.Center(child: pw.AspectRatio(aspectRatio: w / h, child: scan)),
          ),
        );
      } else {
        doc.addPage(
          pw.Page(
            pageFormat: pageFormatFor(w, h),
            margin: pw.EdgeInsets.zero,
            build: (context) => scan,
          ),
        );
      }
    }
    return doc.save();
  }

  /// Draws every word of [text] invisibly (text rendering mode 3) inside
  /// its box on a [size]-sized canvas whose origin is the bottom-left
  /// corner of the scan. The font size follows the box height and the
  /// glyphs are stretched horizontally to span the box width, so a
  /// viewer's search highlight and text selection land on the printed word.
  static void drawTextLayer(PdfGraphics canvas, PdfPoint size, PdfFont font, PageText text) {
    final lineHeight = font.ascent - font.descent; // in em
    for (final word in text.words) {
      final boxW = word.width * size.x, boxH = word.height * size.y;
      if (boxW <= 0 || boxH <= 0 || word.text.isEmpty) continue;
      final fontSize = lineHeight > 0 ? boxH / lineHeight : boxH;
      final x = word.left * size.x;
      final bottom = (1 - word.bottom) * size.y;
      final baseline = bottom - font.descent * fontSize;
      final natural = font.stringMetrics(word.text).advanceWidth * fontSize;
      final scale = natural > 0 ? (boxW / natural).clamp(0.1, 10.0) : null;
      canvas.drawString(font, fontSize, word.text, x, baseline, scale: scale, mode: PdfTextRenderingMode.invisible);
    }
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
