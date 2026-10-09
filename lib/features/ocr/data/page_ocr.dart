import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../../core/models/enums.dart';
import 'ocr_engine.dart';
import 'ocr_preprocessor.dart';
import 'ocr_result.dart';

/// Called before each page is pre-processed and again before it is
/// recognized, with the 1-based page number.
typedef OcrPageProgress = void Function(int page, int total, bool recognizing);

/// Runs OCR over page images: pre-processing in a background isolate, then
/// recognition on the engine's native thread. Shared by the OCR screen and
/// by saving with "searchable PDF".
class PageOcr {
  PageOcr(this._engine, this._tempDir);

  final OcrEngine _engine;

  /// Scratch folder for the prepared images (a sub-folder is created and
  /// removed per [run]).
  final Directory _tempDir;

  /// Recognizes every image in [pageImagePaths]. [shouldStop] lets the
  /// caller abort between steps; the result is then incomplete and the
  /// caller should discard it.
  Future<List<PageText>> run(
    List<String> pageImagePaths,
    OcrLanguage language, {
    OcrPageProgress? onProgress,
    bool Function()? shouldStop,
  }) async {
    final total = pageImagePaths.length;
    final tmpDir = Directory(p.join(_tempDir.path, 'ocr_${DateTime.now().microsecondsSinceEpoch}'));
    await tmpDir.create(recursive: true);
    try {
      final pages = <PageText>[];
      for (var i = 0; i < total; i++) {
        if (shouldStop?.call() ?? false) return pages;
        onProgress?.call(i + 1, total, false);
        final source = await File(pageImagePaths[i]).readAsBytes();
        final prepared = await Isolate.run(() => OcrPreprocessor.prepare(source));
        final preparedPath = p.join(tmpDir.path, 'page_$i.png');
        await File(preparedPath).writeAsBytes(prepared.bytes, flush: true);

        if (shouldStop?.call() ?? false) return pages;
        onProgress?.call(i + 1, total, true);
        final recognized = await _engine.recognize(preparedPath, language);
        final page = recognized.normalized(prepared.width, prepared.height);
        pages.add(PageText(text: cleanText(page.text), words: page.words));
      }
      return pages;
    } finally {
      try {
        await tmpDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Trims trailing spaces and collapses runs of blank lines.
  static String cleanText(String text) => text
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((l) => l.trimRight())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  /// The text of several pages as one document (empty pages skipped).
  static String joinPages(Iterable<PageText> pages) => pages.map((pg) => pg.text).where((t) => t.isNotEmpty).join('\n\n');
}
