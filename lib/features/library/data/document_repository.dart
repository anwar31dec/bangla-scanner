import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/models/enums.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/app_paths.dart';
import '../../../core/storage/storage_providers.dart';

/// Access to saved documents: metadata in drift, files on disk.
class DocumentRepository {
  DocumentRepository(this._db, this._paths);

  final AppDatabase _db;
  final AppPaths _paths;

  static const pagesFolder = 'pages';
  static const pdfFileName = 'document.pdf';
  static const thumbFileName = 'thumb.jpg';

  Stream<List<DocumentRow>> watchAll({String search = '', DocumentSort sort = DocumentSort.newest, int? limit}) =>
      _db.watchDocuments(search: search, sort: sort, limit: limit);

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

  Future<void> delete(DocumentRow doc) async {
    await _db.deleteDocument(doc.id);
    final dir = dirOf(doc);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> upsert(DocumentsCompanion row) => _db.upsertDocument(row);
}

final documentRepositoryProvider = FutureProvider<DocumentRepository>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return DocumentRepository(ref.watch(appDatabaseProvider), paths);
});
