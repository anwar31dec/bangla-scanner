/// Shared enums used across features (settings, export, OCR).
library;

/// Output format for a saved document.
enum SaveFormat { pdf, jpeg }

/// Export quality. Controls the longest page edge in pixels and the JPEG
/// compression level used both for JPEG files and for images inside PDFs.
enum ExportQuality {
  /// ~150 dpi on A4, strong compression. Smallest files, fine for sharing.
  low(maxEdge: 1754, jpegQuality: 55),

  /// ~200 dpi on A4. A good default for most documents.
  medium(maxEdge: 2339, jpegQuality: 72),

  /// ~300 dpi on A4, light compression. Best for printing.
  high(maxEdge: 3508, jpegQuality: 90);

  const ExportQuality({required this.maxEdge, required this.jpegQuality});

  final int maxEdge;
  final int jpegQuality;
}

/// Language choice for OCR.
enum OcrLanguage {
  /// Tesseract with the `ben` model.
  bangla,

  /// Google ML Kit Latin text recognizer.
  english,

  /// Tesseract with `ben+eng` for mixed Bangla/English documents.
  both,
}

/// Image filter applied to a page.
enum PageFilter { original, grayscale, blackWhite, enhanced }
