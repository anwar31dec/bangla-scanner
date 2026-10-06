import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/models/enums.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/app_exception.dart';
import '../data/ocr_engine.dart';
import '../data/ocr_preprocessor.dart';

enum OcrStage { idle, preparing, preprocessing, recognizing, done, failed }

@immutable
class OcrState {
  const OcrState({this.stage = OcrStage.idle, this.current = 0, this.total = 0, this.text = '', this.error});

  final OcrStage stage;

  /// 1-based page currently being processed.
  final int current;
  final int total;
  final String text;
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

/// Runs OCR over a list of page images.
///
/// Pre-processing (resize, grayscale, contrast) runs in a background isolate
/// per page; recognition runs on the engines' native background threads.
class OcrController extends Notifier<OcrState> {
  /// True once the screen that owns this job has been closed.
  bool get _cancelled => !ref.mounted;

  @override
  OcrState build() => const OcrState();

  Future<void> run(List<String> pageImagePaths, OcrLanguage language) async {
    if (state.isRunning) return;
    final total = pageImagePaths.length;
    state = OcrState(stage: OcrStage.preparing, total: total);

    Directory? tmpDir;
    try {
      final engine = await ref.read(ocrEngineProvider.future);
      final paths = await ref.read(appPathsProvider.future);
      tmpDir = Directory(p.join(paths.tempDir.path, 'ocr_${DateTime.now().microsecondsSinceEpoch}'));
      await tmpDir.create(recursive: true);

      final texts = <String>[];
      for (var i = 0; i < total; i++) {
        if (_cancelled) return;
        state = OcrState(stage: OcrStage.preprocessing, current: i + 1, total: total);
        final source = await File(pageImagePaths[i]).readAsBytes();
        final prepared = await Isolate.run(() => OcrPreprocessor.process(source));
        final preparedPath = p.join(tmpDir.path, 'page_$i.png');
        await File(preparedPath).writeAsBytes(prepared, flush: true);

        if (_cancelled) return;
        state = OcrState(stage: OcrStage.recognizing, current: i + 1, total: total);
        final text = await engine.recognize(preparedPath, language);
        texts.add(_clean(text));
      }

      if (_cancelled) return;
      final joined = texts.where((t) => t.isNotEmpty).join('\n\n');
      state = OcrState(stage: OcrStage.done, current: total, total: total, text: joined);
    } catch (e) {
      if (_cancelled) return;
      final error = e is AppException && e.kind != AppErrorKind.generic ? e : AppException(AppErrorKind.ocrFailed, e);
      state = OcrState(stage: OcrStage.failed, total: total, error: error);
    } finally {
      try {
        await tmpDir?.delete(recursive: true);
      } catch (_) {}
    }
  }

  void reset() => state = const OcrState();

  /// Trims trailing spaces and collapses runs of blank lines.
  static String _clean(String text) => text
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((l) => l.trimRight())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
