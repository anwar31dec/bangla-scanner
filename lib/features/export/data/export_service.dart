import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/models/enums.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/app_paths.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/app_exception.dart';
import '../../library/data/document_repository.dart';
import '../../ocr/data/ocr_engine.dart';
import '../../ocr/data/ocr_result.dart';
import '../../ocr/data/page_ocr.dart';
import '../../scan/data/draft_document.dart';
import 'image_processing.dart';

/// Progress callback: [done] pages of [total] processed.
typedef ExportProgress = void Function(int done, int total);

/// Turns a draft into a saved library document (PDF or JPEG).
///
/// All heavy work (decoding, filters, compression, PDF building) runs in
/// background isolates so the UI never freezes.
class ExportService {
  ExportService(this._repo, this._paths, {this._ocrEngine});

  final DocumentRepository _repo;
  final AppPaths _paths;
  final OcrEngine? _ocrEngine;

  static const _uuid = Uuid();

  /// Saves [draft]. A PDF gets [pageSize] pages and, with a [password], is
  /// encrypted so it opens only with that password. [folderId] files a new
  /// document; an existing one keeps its folder and star.
  ///
  /// With an [ocrLanguage] the text of every page is recognized after the
  /// pages are processed ([onOcrProgress] counts pages being read), stored
  /// for the library search and, for a PDF, drawn as an invisible text
  /// layer so the file is searchable anywhere. Without it any text an
  /// edited document had before is dropped: its pages have changed.
  Future<DocumentRow> save({
    required DraftDocument draft,
    required String name,
    required SaveFormat format,
    required ExportQuality quality,
    PdfPageSize pageSize = PdfPageSize.auto,
    String? password,
    String? folderId,
    OcrLanguage? ocrLanguage,
    ExportProgress? onProgress,
    ExportProgress? onOcrProgress,
  }) async {
    if (draft.pages.isEmpty) throw const AppException(AppErrorKind.generic, 'No pages');
    final engine = _ocrEngine;
    if (ocrLanguage != null && engine == null) throw const AppException(AppErrorKind.ocrFailed, 'No OCR engine');

    final existing = draft.existingDocumentId == null ? null : await _repo.get(draft.existingDocumentId!);
    final id = existing?.id ?? _uuid.v4();
    final finalDir = Directory(p.join(_paths.libraryDir.path, id));
    // Build into a staging folder first so a failure (e.g. storage full)
    // never leaves a half-written or destroyed document behind.
    final staging = Directory(p.join(_paths.libraryDir.path, '$id.staging'));

    try {
      if (await staging.exists()) await staging.delete(recursive: true);
      final pagesDir = Directory(p.join(staging.path, DocumentRepository.pagesFolder));
      await pagesDir.create(recursive: true);

      final total = draft.pages.length;
      onProgress?.call(0, total);
      final processed = <Uint8List>[];
      final pagePaths = <String>[];
      for (var i = 0; i < total; i++) {
        final page = draft.pages[i];
        final source = await File(page.imagePath).readAsBytes();
        final turns = page.quarterTurns;
        final filter = page.filter;
        final adjustments = page.adjustments;
        final jpeg = await Isolate.run(
          () => ImageProcessing.processPage(
            source,
            quarterTurns: turns,
            filter: filter,
            adjustments: adjustments,
            quality: quality,
          ),
        );
        final fileName = 'page_${(i + 1).toString().padLeft(3, '0')}.jpg';
        final pagePath = p.join(pagesDir.path, fileName);
        await File(pagePath).writeAsBytes(jpeg, flush: true);
        processed.add(jpeg);
        pagePaths.add(pagePath);
        onProgress?.call(i + 1, total);
      }

      final first = processed.first;
      final thumb = await Isolate.run(() => ImageProcessing.thumbnail(first));
      await File(p.join(staging.path, DocumentRepository.thumbFileName)).writeAsBytes(thumb, flush: true);

      List<PageText?> texts = const [];
      if (ocrLanguage != null && engine != null) {
        onOcrProgress?.call(0, total);
        texts = await PageOcr(engine, _paths.tempDir).run(
          pagePaths,
          ocrLanguage,
          onProgress: (page, total, recognizing) {
            if (recognizing) onOcrProgress?.call(page - 1, total);
          },
        );
        onOcrProgress?.call(total, total);
      }

      final protect = format == SaveFormat.pdf && password != null && password.isNotEmpty;
      int sizeBytes;
      if (format == SaveFormat.pdf) {
        final pdf = await _repo.buildPdf(
          processed,
          title: name,
          pageSize: pageSize,
          password: protect ? password : null,
          texts: texts,
        );
        await File(p.join(staging.path, DocumentRepository.pdfFileName)).writeAsBytes(pdf, flush: true);
        sizeBytes = pdf.length;
      } else {
        sizeBytes = processed.fold(0, (sum, b) => sum + b.length);
      }

      // Swap staging → final.
      if (await finalDir.exists()) await finalDir.delete(recursive: true);
      await staging.rename(finalDir.path);

      final now = DateTime.now();
      await _repo.upsert(
        DocumentsCompanion(
          id: Value(id),
          name: Value(name.trim()),
          format: Value(format),
          dirPath: Value(_paths.relative(finalDir.path)),
          pageCount: Value(total),
          sizeBytes: Value(sizeBytes),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
          isFavorite: Value(existing?.isFavorite ?? false),
          folderId: Value(existing?.folderId ?? folderId),
          isProtected: Value(protect),
        ),
      );
      // Sets hasText as well (and clears stale text of an edited document).
      await _repo.setPageTexts(id, texts, ocrLanguage ?? OcrLanguage.bangla);
      final saved = await _repo.get(id);
      return saved!;
    } catch (e) {
      try {
        if (await staging.exists()) await staging.delete(recursive: true);
      } catch (_) {}
      throw AppException.from(e);
    }
  }
}

final exportServiceProvider = FutureProvider<ExportService>((ref) async {
  return ExportService(
    await ref.watch(documentRepositoryProvider.future),
    await ref.watch(appPathsProvider.future),
    ocrEngine: await ref.watch(ocrEngineProvider.future),
  );
});
