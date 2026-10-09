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
import '../../export/data/image_processing.dart';
import '../../export/data/pdf_builder.dart';

/// Access to saved documents: metadata in drift, files on disk.
class DocumentRepository {
  DocumentRepository(this._db, this._paths);

  final AppDatabase _db;
  final AppPaths _paths;

  static const pagesFolder = 'pages';
  static const pdfFileName = 'document.pdf';
  static const thumbFileName = 'thumb.jpg';
  static const _uuid = Uuid();

  Stream<List<DocumentRow>> watchAll({
    String search = '',
    DocumentSort sort = DocumentSort.newest,
    LibraryFilter filter = LibraryFilter.all,
    int? limit,
  }) =>
      _db.watchDocuments(search: search, sort: sort, filter: filter, limit: limit);

  Stream<DocumentRow?> watch(String id) => _db.watchDocument(id);

  Future<DocumentRow?> get(String id) => _db.getDocument(id);

  Directory dirOf(DocumentRow doc) => Directory(_paths.absolute(doc.dirPath));

  File thumbnailOf(DocumentRow doc) => File(p.join(dirOf(doc).path, thumbFileName));

  File pdfOf(DocumentRow doc) => File(p.join(dirOf(doc).path, pdfFileName));

  /// Processed page images in page order.
  Future<List<File>> pagesOf(DocumentRow doc) async {
    final dir = Directory(p.join(dirOf(doc).path, pagesFolder));
    if (!await dir.exists()) return const [];
    final files = await dir.list().where((e) => e is File && e.path.endsWith('.jpg')).cast<File>().toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// The files that make up the document as the user sees it: the PDF, or
  /// every page JPEG.
  Future<List<File>> outputFilesOf(DocumentRow doc) async =>
      doc.format == SaveFormat.pdf ? [pdfOf(doc)] : await pagesOf(doc);

  /// True when all files the document needs are still on disk.
  Future<bool> isIntact(DocumentRow doc) async {
    final outputs = await outputFilesOf(doc);
    if (outputs.isEmpty) return false;
    for (final f in outputs) {
      if (!await f.exists()) return false;
    }
    return true;
  }

  Future<void> rename(String id, String name) => _db.renameDocument(id, name.trim());

  Future<void> setFavorite(String id, bool favorite) => _db.setFavorite(id, favorite);

  Future<void> moveToFolder(List<String> ids, String? folderId) => _db.moveToFolder(ids, folderId);

  Future<void> delete(DocumentRow doc) async {
    await _db.deleteDocument(doc.id);
    final dir = dirOf(doc);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> deleteAll(Iterable<DocumentRow> docs) async {
    for (final doc in docs) {
      await delete(doc);
    }
  }

  Future<void> upsert(DocumentsCompanion row) => _db.upsertDocument(row);

  /// Rewrites the document with its pages in the order of [keptPages]
  /// (a subset of [pagesOf], reordered; left-out pages are removed). The
  /// JPEGs are moved, not re-encoded, so nothing loses quality. A PDF is
  /// rebuilt; a protected one needs its [password] again.
  Future<void> rewritePages(DocumentRow doc, List<File> keptPages, {String? password}) async {
    if (keptPages.isEmpty) throw const AppException(AppErrorKind.generic, 'No pages');
    final dir = dirOf(doc);
    final staging = Directory('${dir.path}.staging');
    try {
      if (await staging.exists()) await staging.delete(recursive: true);
      final pagesDir = Directory(p.join(staging.path, pagesFolder));
      await pagesDir.create(recursive: true);

      final bytes = <Uint8List>[];
      for (var i = 0; i < keptPages.length; i++) {
        final name = 'page_${(i + 1).toString().padLeft(3, '0')}.jpg';
        final copy = await keptPages[i].copy(p.join(pagesDir.path, name));
        bytes.add(await copy.readAsBytes());
      }
      final first = bytes.first;
      final thumb = await Isolate.run(() => ImageProcessing.thumbnail(first));
      await File(p.join(staging.path, thumbFileName)).writeAsBytes(thumb, flush: true);

      final protect = doc.format == SaveFormat.pdf && password != null && password.isNotEmpty;
      int sizeBytes;
      if (doc.format == SaveFormat.pdf) {
        final title = doc.name;
        final pdf = await Isolate.run(() => PdfBuilder.build(bytes, title: title, password: protect ? password : null));
        await File(p.join(staging.path, pdfFileName)).writeAsBytes(pdf, flush: true);
        sizeBytes = pdf.length;
      } else {
        sizeBytes = bytes.fold(0, (sum, b) => sum + b.length);
      }

      if (await dir.exists()) await dir.delete(recursive: true);
      await staging.rename(dir.path);
      await _db.upsertDocument(
        DocumentsCompanion(
          id: Value(doc.id),
          name: Value(doc.name),
          format: Value(doc.format),
          dirPath: Value(doc.dirPath),
          pageCount: Value(keptPages.length),
          sizeBytes: Value(sizeBytes),
          createdAt: Value(doc.createdAt),
          updatedAt: Value(DateTime.now()),
          isFavorite: Value(doc.isFavorite),
          folderId: Value(doc.folderId),
          isProtected: Value(protect),
        ),
      );
    } catch (e) {
      try {
        if (await staging.exists()) await staging.delete(recursive: true);
      } catch (_) {}
      throw AppException.from(e);
    }
  }

  // Folders -----------------------------------------------------------------

  Stream<List<FolderRow>> watchFolders() => _db.watchFolders();

  Stream<Map<String, int>> watchFolderCounts() => _db.watchFolderCounts();

  Future<FolderRow> createFolder(String name) async {
    final row = FolderRow(id: _uuid.v4(), name: name.trim(), createdAt: DateTime.now());
    await _db.insertFolder(row);
    return row;
  }

  Future<void> renameFolder(String id, String name) => _db.renameFolder(id, name.trim());

  /// Deletes the folder only; its documents stay in the library.
  Future<void> deleteFolder(String id) => _db.deleteFolder(id);
}

final documentRepositoryProvider = FutureProvider<DocumentRepository>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return DocumentRepository(ref.watch(appDatabaseProvider), paths);
});
