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

  @override
  Set<Column> get primaryKey => {id};
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

@DriftDatabase(tables: [Documents, Folders])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'bangla_scanner'));

  @override
  int get schemaVersion => 2;

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
        },
      );

  /// Live list of documents, optionally filtered by [search] (case
  /// insensitive, matches anywhere in the name) and [filter].
  Stream<List<DocumentRow>> watchDocuments({
    String search = '',
    DocumentSort sort = DocumentSort.newest,
    LibraryFilter filter = LibraryFilter.all,
    int? limit,
  }) {
    final query = select(documents);
    final term = search.trim();
    if (term.isNotEmpty) {
      final escaped = term.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
      query.where((d) => d.name.lower().like('%${escaped.toLowerCase()}%', escapeChar: r'\'));
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

  Future<void> deleteDocument(String id) => (delete(documents)..where((d) => d.id.equals(id))).go();

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
