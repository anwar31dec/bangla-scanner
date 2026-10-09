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

/// Paper size of the pages of a saved PDF.
enum PdfPageSize {
  /// Each page takes the shape of its scan (no white bands).
  auto(widthMm: 0, heightMm: 0),

  /// ISO A4, 210 × 297 mm. The scan is fitted inside with a small margin.
  a4(widthMm: 210, heightMm: 297),

  /// US Letter, 8.5 × 11 in.
  letter(widthMm: 215.9, heightMm: 279.4),

  /// US Legal, 8.5 × 14 in.
  legal(widthMm: 215.9, heightMm: 355.6);

  const PdfPageSize({required this.widthMm, required this.heightMm});

  final double widthMm;
  final double heightMm;

  bool get isFixed => this != PdfPageSize.auto;
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
enum PageFilter {
  /// The photo as taken.
  original,

  /// White paper, no shadows, colours kept. The classic "scanned" look.
  autoColor,

  /// Like [autoColor] without colour.
  grayscale,

  /// Pure black ink on pure white. Smallest files.
  blackWhite,

  /// For whiteboards: removes glare and grey cast, boosts marker colours.
  whiteboard,

  /// Darkens faint writing such as pencil or weak print.
  lightText,
}

/// How long the app may stay in the background before it locks again.
enum LockDelay {
  immediately(seconds: 0),
  oneMinute(seconds: 60),
  fiveMinutes(seconds: 300);

  const LockDelay({required this.seconds});

  final int seconds;
}

/// Physical card formats for the ID card page.
enum CardKind {
  /// ISO/IEC 7810 ID-1: NID smart card, driving licence, bank cards.
  idCard(widthMm: 85.6, heightMm: 53.98, needsBack: true),

  /// ISO/IEC 7810 ID-3: a passport data page.
  passport(widthMm: 125, heightMm: 88, needsBack: false);

  const CardKind({required this.widthMm, required this.heightMm, required this.needsBack});

  final double widthMm;
  final double heightMm;

  /// Whether the flow asks for a second side before the page can be made.
  final bool needsBack;
}
