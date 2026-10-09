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
import '../../ocr/data/ocr_result.dart';

/// Access to saved documents: metadata in drift, files on disk.
class DocumentRepository {
  DocumentRepository(this._db, this._paths, {this._loadFont = TextLayerFont.load});

  final AppDatabase _db;
  final AppPaths _paths;
  final TextLayerFontLoader _loadFont;

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

  /// Documents whose recognized text contains [term], with the text of the
  /// first matching page (see [textSnippet]).
  Stream<Map<String, String>> watchTextMatches(String term) => _db.watchTextMatches(term);

  /// A short, single-line excerpt of [text] around the first occurrence of
  /// [term] (case-insensitive), with an ellipsis on the cut sides.
  static String textSnippet(String text, String term, {int radius = 32}) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final t = term.trim();
    final at = t.isEmpty ? -1 : flat.toLowerCase().indexOf(t.toLowerCase());
    if (at < 0) return flat.length <= 2 * radius ? flat : '${flat.substring(0, 2 * radius)}…';
    final start = (at - radius).clamp(0, flat.length);
    final end = (at + t.length + radius).clamp(0, flat.length);
    return '${start > 0 ? '…' : ''}${flat.substring(start, end)}${end < flat.length ? '…' : ''}';
  }

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

  // Recognized text ---------------------------------------------------------

  /// Recognized text per page (null for pages without any), as long as the
  /// document has pages.
  Future<List<PageText?>> pageTextsOf(DocumentRow doc) async {
    final rows = await _db.pageTextsOf(doc.id);
    final out = List<PageText?>.filled(doc.pageCount, null);
    for (final r in rows) {
      if (r.pageIndex >= 0 && r.pageIndex < out.length) {
        out[r.pageIndex] = PageText(text: r.content, words: PageText.wordsFromJson(r.words));
      }
    }
    return out;
  }

  /// Stores the recognized [pages] (in page order) of [doc], replacing any
  /// earlier text. An empty list clears it.
  Future<void> setPageTexts(String documentId, List<PageText?> pages, OcrLanguage language) => _db.setPageTexts(
        documentId,
        [
          for (var i = 0; i < pages.length; i++)
            if (pages[i] case final page? when !page.isEmpty || page.words.isNotEmpty)
              PageTextsCompanion.insert(
                documentId: documentId,
                pageIndex: i,
                content: page.text,
                words: Value(page.wordsJson),
                language: language,
              ),
        ],
      );

  /// Builds the PDF bytes for [pages], with an invisible text layer when
  /// any of [texts] has word positions.
  Future<Uint8List> buildPdf(
    List<Uint8List> pages, {
    required String title,
    String? password,
    List<PageText?>? texts,
    PdfPageSize pageSize = PdfPageSize.auto,
  }) async {
    final hasWords = texts?.any((t) => t != null && t.words.isNotEmpty) ?? false;
    final font = hasWords ? await _loadFont() : null;
    return Isolate.run(
      () => PdfBuilder.build(pages, title: title, pageSize: pageSize, password: password, texts: texts, fontData: font),
    );
  }

  /// Rebuilds the PDF of [doc] from its page images and stored text, so a
  /// freshly recognized document becomes searchable in any PDF viewer. A
  /// protected PDF needs its [password] again. JPEG documents are left
  /// alone.
  Future<void> rebuildPdf(DocumentRow doc, {String? password}) async {
    if (doc.format != SaveFormat.pdf) return;
    final pages = await pagesOf(doc);
    if (pages.isEmpty) throw const AppException(AppErrorKind.missingFile);
    final bytes = [for (final f in pages) await f.readAsBytes()];
    final texts = await pageTextsOf(doc);
    final protect = password != null && password.isNotEmpty;
    final pdf = await buildPdf(bytes, title: doc.name, password: protect ? password : null, texts: texts);
    final target = pdfOf(doc);
    // Write next to the file and rename, so a crash never leaves half a PDF.
    final tmp = File('${target.path}.tmp');
    try {
      await tmp.writeAsBytes(pdf, flush: true);
      await tmp.rename(target.path);
    } catch (e) {
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      throw AppException.from(e);
    }
    await _db.upsertDocument(
      DocumentsCompanion(
        id: Value(doc.id),
        name: Value(doc.name),
        format: Value(doc.format),
        dirPath: Value(doc.dirPath),
        pageCount: Value(doc.pageCount),
        sizeBytes: Value(pdf.length),
        createdAt: Value(doc.createdAt),
        updatedAt: Value(DateTime.now()),
        isFavorite: Value(doc.isFavorite),
        folderId: Value(doc.folderId),
        isProtected: Value(protect),
        hasText: Value(doc.hasText),
      ),
    );
  }

  /// 0-based page number of a `page_NNN.jpg` file, or null.
  static int? pageIndexOf(File page) {
    final m = RegExp(r'^page_(\d+)\.jpg$').firstMatch(p.basename(page.path));
    return m == null ? null : int.parse(m.group(1)!) - 1;
  }

  /// Rewrites the document with its pages in the order of [keptPages]
  /// (a subset of [pagesOf], reordered; left-out pages are removed). The
  /// JPEGs are moved, not re-encoded, so nothing loses quality, and the
  /// recognized text follows its page. A PDF is rebuilt; a protected one
  /// needs its [password] again.
  Future<void> rewritePages(DocumentRow doc, List<File> keptPages, {String? password}) async {
    if (keptPages.isEmpty) throw const AppException(AppErrorKind.generic, 'No pages');
    final dir = dirOf(doc);
    final staging = Directory('${dir.path}.staging');
    try {
      if (await staging.exists()) await staging.delete(recursive: true);
      final pagesDir = Directory(p.join(staging.path, pagesFolder));
      await pagesDir.create(recursive: true);

      final oldTexts = await pageTextsOf(doc);
      final oldRows = await _db.pageTextsOf(doc.id);
      final language = oldRows.isEmpty ? OcrLanguage.bangla : oldRows.first.language;
      final texts = <PageText?>[];
      final bytes = <Uint8List>[];
      for (var i = 0; i < keptPages.length; i++) {
        final name = 'page_${(i + 1).toString().padLeft(3, '0')}.jpg';
        final copy = await keptPages[i].copy(p.join(pagesDir.path, name));
        bytes.add(await copy.readAsBytes());
        final oldIndex = pageIndexOf(keptPages[i]);
        texts.add(oldIndex != null && oldIndex < oldTexts.length ? oldTexts[oldIndex] : null);
      }
      final first = bytes.first;
      final thumb = await Isolate.run(() => ImageProcessing.thumbnail(first));
      await File(p.join(staging.path, thumbFileName)).writeAsBytes(thumb, flush: true);

      final protect = doc.format == SaveFormat.pdf && password != null && password.isNotEmpty;
      int sizeBytes;
      if (doc.format == SaveFormat.pdf) {
        final pdf = await buildPdf(bytes, title: doc.name, password: protect ? password : null, texts: texts);
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
          hasText: Value(doc.hasText),
        ),
      );
      await setPageTexts(doc.id, texts, language);
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
