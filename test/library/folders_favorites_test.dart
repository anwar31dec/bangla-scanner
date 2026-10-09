import 'dart:io';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/features/library/data/document_repository.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_app.dart';

Future<void> _insert(AppDatabase db, String id, String name, {bool favorite = false, String? folderId}) => db.upsertDocument(
      DocumentsCompanion(
        id: Value(id),
        name: Value(name),
        format: const Value(SaveFormat.pdf),
        dirPath: Value('library/$id'),
        pageCount: const Value(1),
        sizeBytes: const Value(1000),
        createdAt: Value(DateTime(2026, 10, 1)),
        updatedAt: Value(DateTime(2026, 10, 1)),
        isFavorite: Value(favorite),
        folderId: Value(folderId),
      ),
    );

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  group('DocumentRepository folders and favourites', () {
    late Directory root;
    late AppDatabase db;
    late DocumentRepository repo;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('bs_lib');
      db = AppDatabase(NativeDatabase.memory());
      repo = DocumentRepository(db, AppPaths(root, root));
    });

    tearDown(() async {
      await db.close();
      await root.delete(recursive: true);
    });

    test('favourites filter and star toggle', () async {
      await _insert(db, 'a', 'Plain');
      await _insert(db, 'b', 'Starred', favorite: true);
      expect((await repo.watchAll(filter: LibraryFilter.favorites).first).map((d) => d.id), ['b']);
      await repo.setFavorite('a', true);
      expect((await repo.watchAll(filter: LibraryFilter.favorites).first).length, 2);
      await repo.setFavorite('b', false);
      expect((await repo.watchAll(filter: LibraryFilter.favorites).first).map((d) => d.id), ['a']);
    });

    test('folders: create, move, count, rename, delete keeps documents', () async {
      await _insert(db, 'a', 'Bank');
      await _insert(db, 'b', 'Birth');
      await _insert(db, 'c', 'Other');
      final bills = await repo.createFolder('  Bills ');
      expect(bills.name, 'Bills');
      await repo.moveToFolder(['a', 'b'], bills.id);

      expect((await repo.watchAll(filter: LibraryFilter.folder(bills.id)).first).map((d) => d.name), ['Birth', 'Bank']);
      expect(await repo.watchFolderCounts().first, {bills.id: 2});
      expect((await repo.watchAll().first).length, 3, reason: 'All still shows everything');

      await repo.moveToFolder(['b'], null);
      expect(await repo.watchFolderCounts().first, {bills.id: 1});

      await repo.renameFolder(bills.id, 'Payments');
      expect((await repo.watchFolders().first).single.name, 'Payments');

      await repo.deleteFolder(bills.id);
      expect(await repo.watchFolders().first, isEmpty);
      expect((await repo.watchAll().first).length, 3);
      expect((await repo.get('a'))!.folderId, isNull);
    });

    test('search combines with the folder filter', () async {
      final f = await repo.createFolder('Tax');
      await _insert(db, 'a', 'Tax return 2025', folderId: f.id);
      await _insert(db, 'b', 'Tax return 2024');
      final hits = await repo.watchAll(search: 'return', filter: LibraryFilter.folder(f.id)).first;
      expect(hits.map((d) => d.id), ['a']);
    });
  });

  testWidgets('library shows folder chips, stars favourites and filters by folder', (tester) async {
    final (app, db, _) = await buildTestApp(prefs: {'settings.language': 'en'});
    addTearDown(db.close);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final String folderId;
    await tester.runAsync(() async {
      final row = FolderRow(id: 'f1', name: 'Bills', createdAt: DateTime(2026, 10, 1));
      await db.insertFolder(row);
      await _insert(db, 'a', 'Electricity', folderId: 'f1', favorite: true);
      await _insert(db, 'b', 'Passport copy');
    });
    folderId = 'f1';

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.text('Bills (1)'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets, reason: 'favourite star on the tile');

    await tester.tap(find.text('Bills (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Electricity'), findsOneWidget);
    expect(find.text('Passport copy'), findsNothing);

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();
    expect(find.text('Electricity'), findsOneWidget);
    expect(find.text('Passport copy'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Passport copy'), findsOneWidget);

    // Multi-select: pick both and delete them in one go.
    await tester.tap(find.byTooltip('Select'));
    await tester.pumpAndSettle();
    expect(find.text('Select documents'), findsOneWidget);
    await tester.tap(find.byTooltip('Select all'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 documents?'), findsOneWidget);
    // Deleting touches the database and the disk; pump between real waits
    // until the screen has left selection mode.
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      for (var i = 0; i < 30 && find.text('2 selected').evaluate().isNotEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Electricity'), findsNothing);
    expect(find.text('Passport copy'), findsNothing);
    expect(await db.getDocument('a'), isNull);
    expect(await db.getDocument('b'), isNull);
    expect(find.text('2 selected'), findsNothing, reason: 'selection mode ends after deleting');
    expect(find.textContaining('Bills'), findsOneWidget, reason: 'folder $folderId stays, now empty');
    await unmountApp(tester);
  });
}
