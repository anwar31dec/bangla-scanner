import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/enums.dart';

part 'app_database.g.dart';

/// Metadata for each saved document. The files themselves live on disk
/// under [AppPaths.libraryDir]; see `AppPaths` for the layout.
@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get format => textEnum<SaveFormat>()();

  /// Folder of the document, relative to the app documents directory.
  TextColumn get dirPath => text()();
  IntColumn get pageCount => integer()();

  /// Size of the output (PDF file, or all JPEG pages) in bytes.
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Starred by the user.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Library folder the document is filed in (null = no folder).
  TextColumn get folderId => text().nullable()();

  /// True when the PDF was saved with an open password. The password itself
  /// is never stored.
  BoolColumn get isProtected => boolean().withDefault(const Constant(false))();

  /// True when OCR text is stored for the document (see [PageTexts]), so the
  /// library search looks inside it and a PDF carries a text layer.
  BoolColumn get hasText => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recognized text of one page of a document, with the position of every
/// word (see `PageText`). Powers the library's full-text search and the
/// invisible text layer of searchable PDFs.
@DataClassName('PageTextRow')
class PageTexts extends Table {
  TextColumn get documentId => text()();

  /// 0-based page number.
  IntColumn get pageIndex => integer()();
  TextColumn get content => text()();

  /// JSON list of `[word, left, top, right, bottom]` (fractions of the page).
  TextColumn get words => text().withDefault(const Constant('[]'))();
  TextColumn get language => textEnum<OcrLanguage>()();

  @override
  Set<Column> get primaryKey => {documentId, pageIndex};
}

/// User-created folders of the library.
@DataClassName('FolderRow')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sort orders offered in the library.
enum DocumentSort { newest, oldest, nameAz, nameZa }

/// Which documents the library shows.
sealed class LibraryFilter {
  const LibraryFilter();

  /// Every document.
  static const LibraryFilter all = _AllFilter();

  /// Only starred documents.
  static const LibraryFilter favorites = _FavoritesFilter();

  /// Documents filed in one folder.
  const factory LibraryFilter.folder(String folderId) = FolderFilter;
}

class _AllFilter extends LibraryFilter {
  const _AllFilter();
}

class _FavoritesFilter extends LibraryFilter {
  const _FavoritesFilter();
}

class FolderFilter extends LibraryFilter {
  const FolderFilter(this.folderId);

  final String folderId;

  @override
  bool operator ==(Object other) => other is FolderFilter && other.folderId == folderId;

  @override
  int get hashCode => folderId.hashCode;
}

@DriftDatabase(tables: [Documents, Folders, PageTexts])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'bangla_scanner'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(documents, documents.isFavorite);
            await m.addColumn(documents, documents.folderId);
            await m.addColumn(documents, documents.isProtected);
            await m.createTable(folders);
          }
          if (from < 3) {
            await m.addColumn(documents, documents.hasText);
            await m.createTable(pageTexts);
          }
        },
      );

  /// `%term%` for a LIKE on lower-cased text, with the wildcards escaped.
  static String _likePattern(String term) {
    final escaped = term.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    return '%${escaped.toLowerCase()}%';
  }

  /// Live list of documents, optionally filtered by [search] (case
  /// insensitive, matches anywhere in the name or in the recognized text
  /// of a page) and [filter].
  Stream<List<DocumentRow>> watchDocuments({
    String search = '',
    DocumentSort sort = DocumentSort.newest,
    LibraryFilter filter = LibraryFilter.all,
    int? limit,
  }) {
    final query = select(documents);
    final term = search.trim();
    if (term.isNotEmpty) {
      final pattern = _likePattern(term);
      query.where(
        (d) =>
            d.name.lower().like(pattern, escapeChar: r'\') |
            existsQuery(
              select(pageTexts)
                ..where((t) => t.documentId.equalsExp(d.id) & t.content.lower().like(pattern, escapeChar: r'\')),
            ),
      );
    }
    switch (filter) {
      case _AllFilter():
        break;
      case _FavoritesFilter():
        query.where((d) => d.isFavorite.equals(true));
      case FolderFilter(:final folderId):
        query.where((d) => d.folderId.equals(folderId));
    }
    query.orderBy([
      (d) => switch (sort) {
            DocumentSort.newest => OrderingTerm.desc(d.createdAt),
            DocumentSort.oldest => OrderingTerm.asc(d.createdAt),
            DocumentSort.nameAz => OrderingTerm.asc(d.name.collate(Collate.noCase)),
            DocumentSort.nameZa => OrderingTerm.desc(d.name.collate(Collate.noCase)),
          },
      // Timestamps have one-second precision; insertion order breaks ties.
      (d) => sort == DocumentSort.oldest ? OrderingTerm.asc(d.rowId) : OrderingTerm.desc(d.rowId),
    ]);
    if (limit != null) query.limit(limit);
    return query.watch();
  }

  Stream<DocumentRow?> watchDocument(String id) =>
      (select(documents)..where((d) => d.id.equals(id))).watchSingleOrNull();

  Future<DocumentRow?> getDocument(String id) =>
      (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();

  /// Every document, oldest first (backup order).
  Future<List<DocumentRow>> allDocuments() =>
      (select(documents)..orderBy([(d) => OrderingTerm.asc(d.createdAt), (d) => OrderingTerm.asc(d.rowId)])).get();

  Future<List<FolderRow>> allFolders() => select(folders).get();

  Future<void> upsertDocument(DocumentsCompanion row) => into(documents).insertOnConflictUpdate(row);

  Future<void> renameDocument(String id, String name) =>
      (update(documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
      );

  Future<void> setFavorite(String id, bool favorite) =>
      (update(documents)..where((d) => d.id.equals(id))).write(DocumentsCompanion(isFavorite: Value(favorite)));

  /// Files [ids] in [folderId] (null removes them from their folder).
  Future<void> moveToFolder(List<String> ids, String? folderId) =>
      (update(documents)..where((d) => d.id.isIn(ids))).write(DocumentsCompanion(folderId: Value(folderId)));

  Future<void> deleteDocument(String id) => transaction(() async {
        await (delete(pageTexts)..where((t) => t.documentId.equals(id))).go();
        await (delete(documents)..where((d) => d.id.equals(id))).go();
      });

  // Page texts ---------------------------------------------------------------

  /// Recognized text of every page of document [id], in page order.
  Future<List<PageTextRow>> pageTextsOf(String id) =>
      (select(pageTexts)
            ..where((t) => t.documentId.equals(id))
            ..orderBy([(t) => OrderingTerm.asc(t.pageIndex)]))
          .get();

  /// Replaces the recognized text of document [id] with [rows] (which may
  /// be empty to clear it) and keeps the document's `hasText` flag in step.
  Future<void> setPageTexts(String id, List<PageTextsCompanion> rows) => transaction(() async {
        await (delete(pageTexts)..where((t) => t.documentId.equals(id))).go();
        await batch((b) => b.insertAll(pageTexts, rows));
        final hasText = rows.any((r) => r.content.present && r.content.value.trim().isNotEmpty);
        await (update(documents)..where((d) => d.id.equals(id)))
            .write(DocumentsCompanion(hasText: Value(hasText)));
      });

  /// For a search [term], the first page text of each matching document,
  /// live. Used to show where in the text a search hit was found.
  Stream<Map<String, String>> watchTextMatches(String term) {
    final t = term.trim();
    if (t.isEmpty) return Stream.value(const {});
    final query = select(pageTexts)
      ..where((p) => p.content.lower().like(_likePattern(t), escapeChar: r'\'))
      ..orderBy([(p) => OrderingTerm.asc(p.documentId), (p) => OrderingTerm.asc(p.pageIndex)]);
    return query.watch().map((rows) {
      final out = <String, String>{};
      for (final r in rows) {
        out.putIfAbsent(r.documentId, () => r.content);
      }
      return out;
    });
  }

  // Folders -----------------------------------------------------------------

  Stream<List<FolderRow>> watchFolders() =>
      (select(folders)..orderBy([(f) => OrderingTerm.asc(f.name.collate(Collate.noCase))])).watch();

  Future<void> insertFolder(FolderRow row) => into(folders).insert(row);

  Future<void> renameFolder(String id, String name) =>
      (update(folders)..where((f) => f.id.equals(id))).write(FoldersCompanion(name: Value(name)));

  /// Deletes the folder; its documents are kept and end up in no folder.
  Future<void> deleteFolder(String id) => transaction(() async {
        await (update(documents)..where((d) => d.folderId.equals(id)))
            .write(const DocumentsCompanion(folderId: Value(null)));
        await (delete(folders)..where((f) => f.id.equals(id))).go();
      });

  /// Number of documents in each folder, live.
  Stream<Map<String, int>> watchFolderCounts() {
    final count = documents.id.count();
    final query = selectOnly(documents)
      ..addColumns([documents.folderId, count])
      ..where(documents.folderId.isNotNull())
      ..groupBy([documents.folderId]);
    return query.watch().map((rows) => {for (final r in rows) r.read(documents.folderId)!: r.read(count) ?? 0});
  }
}
