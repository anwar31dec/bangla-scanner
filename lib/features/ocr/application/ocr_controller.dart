import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/app_exception.dart';
import '../data/ocr_engine.dart';
import '../data/ocr_result.dart';
import '../data/page_ocr.dart';

enum OcrStage { idle, preparing, preprocessing, recognizing, done, failed }

@immutable
class OcrState {
  const OcrState({
    this.stage = OcrStage.idle,
    this.current = 0,
    this.total = 0,
    this.text = '',
    this.pages = const [],
    this.language,
    this.error,
  });

  final OcrStage stage;

  /// 1-based page currently being processed.
  final int current;
  final int total;

  /// All pages' text joined, ready for the editor.
  final String text;

  /// Per-page result (text and word boxes), in page order.
  final List<PageText> pages;

  /// Language the job ran with.
  final OcrLanguage? language;
  final AppException? error;

  bool get isRunning =>
      stage == OcrStage.preparing || stage == OcrStage.preprocessing || stage == OcrStage.recognizing;

  /// 0..1 overall progress (each page = preprocessing + recognition).
  double? get progress {
    if (total == 0 || stage == OcrStage.preparing) return null;
    final steps = (current - 1) * 2 + (stage == OcrStage.recognizing ? 1 : 0);
    return (steps / (total * 2)).clamp(0, 1).toDouble();
  }
}

final ocrControllerProvider = NotifierProvider.autoDispose<OcrController, OcrState>(OcrController.new);

/// Runs OCR over a list of page images (see [PageOcr]).
class OcrController extends Notifier<OcrState> {
  /// True once the screen that owns this job has been closed.
  bool get _cancelled => !ref.mounted;

  @override
  OcrState build() => const OcrState();

  Future<void> run(List<String> pageImagePaths, OcrLanguage language) async {
    if (state.isRunning) return;
    final total = pageImagePaths.length;
    state = OcrState(stage: OcrStage.preparing, total: total, language: language);

    try {
      final engine = await ref.read(ocrEngineProvider.future);
      final paths = await ref.read(appPathsProvider.future);
      final pages = await PageOcr(engine, paths.tempDir).run(
        pageImagePaths,
        language,
        shouldStop: () => _cancelled,
        onProgress: (page, total, recognizing) {
          if (_cancelled) return;
          state = OcrState(
            stage: recognizing ? OcrStage.recognizing : OcrStage.preprocessing,
            current: page,
            total: total,
            language: language,
          );
        },
      );
      if (_cancelled) return;
      state = OcrState(
        stage: OcrStage.done,
        current: total,
        total: total,
        text: PageOcr.joinPages(pages),
        pages: pages,
        language: language,
      );
    } catch (e) {
      if (_cancelled) return;
      final error = e is AppException && e.kind != AppErrorKind.generic ? e : AppException(AppErrorKind.ocrFailed, e);
      state = OcrState(stage: OcrStage.failed, total: total, language: language, error: error);
    }
  }

  void reset() => state = const OcrState();
}
