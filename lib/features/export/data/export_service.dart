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
import '../../scan/data/draft_document.dart';
import 'image_processing.dart';
import 'pdf_builder.dart';

/// Progress callback: [done] pages of [total] processed.
typedef ExportProgress = void Function(int done, int total);

/// Turns a draft into a saved library document (PDF or JPEG).
///
/// All heavy work (decoding, filters, compression, PDF building) runs in
/// background isolates so the UI never freezes.
class ExportService {
  ExportService(this._repo, this._paths);

  final DocumentRepository _repo;
  final AppPaths _paths;

  static const _uuid = Uuid();

  Future<DocumentRow> save({
    required DraftDocument draft,
    required String name,
    required SaveFormat format,
    required ExportQuality quality,
    ExportProgress? onProgress,
  }) async {
    if (draft.pages.isEmpty) throw const AppException(AppErrorKind.generic, 'No pages');

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
      for (var i = 0; i < total; i++) {
        final page = draft.pages[i];
        final source = await File(page.imagePath).readAsBytes();
        final turns = page.quarterTurns;
        final filter = page.filter;
        final jpeg = await Isolate.run(
          () => ImageProcessing.processPage(source, quarterTurns: turns, filter: filter, quality: quality),
        );
        final fileName = 'page_${(i + 1).toString().padLeft(3, '0')}.jpg';
        await File(p.join(pagesDir.path, fileName)).writeAsBytes(jpeg, flush: true);
        processed.add(jpeg);
        onProgress?.call(i + 1, total);
      }

      final first = processed.first;
      final thumb = await Isolate.run(() => ImageProcessing.thumbnail(first));
      await File(p.join(staging.path, DocumentRepository.thumbFileName)).writeAsBytes(thumb, flush: true);

      int sizeBytes;
      if (format == SaveFormat.pdf) {
        final pdf = await Isolate.run(() => PdfBuilder.build(processed, title: name));
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
        ),
      );
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
  return ExportService(await ref.watch(documentRepositoryProvider.future), await ref.watch(appPathsProvider.future));
});
