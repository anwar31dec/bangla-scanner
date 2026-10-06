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

  @override
  Set<Column> get primaryKey => {id};
}

/// Sort orders offered in the library.
enum DocumentSort { newest, oldest, nameAz, nameZa }

@DriftDatabase(tables: [Documents])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'bangla_scanner'));

  @override
  int get schemaVersion => 1;

  /// Live list of documents, optionally filtered by [search] (case
  /// insensitive, matches anywhere in the name).
  Stream<List<DocumentRow>> watchDocuments({
    String search = '',
    DocumentSort sort = DocumentSort.newest,
    int? limit,
  }) {
    final query = select(documents);
    final term = search.trim();
    if (term.isNotEmpty) {
      final escaped = term.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
      query.where((d) => d.name.lower().like('%${escaped.toLowerCase()}%', escapeChar: r'\'));
    }
    query.orderBy([
      (d) => switch (sort) {
            DocumentSort.newest => OrderingTerm.desc(d.createdAt),
            DocumentSort.oldest => OrderingTerm.asc(d.createdAt),
            DocumentSort.nameAz => OrderingTerm.asc(d.name.collate(Collate.noCase)),
            DocumentSort.nameZa => OrderingTerm.desc(d.name.collate(Collate.noCase)),
          },
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

  Future<void> deleteDocument(String id) => (delete(documents)..where((d) => d.id.equals(id))).go();
}
