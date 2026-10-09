import 'dart:io';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';
import '../test_app.dart';

/// Inserts a document with [pages] real page JPEGs on disk.
Future<void> _insertWithPages(AppDatabase db, AppPaths paths, String id, String name, DateTime created, int pages) async {
  final dir = Directory(p.join(paths.libraryDir.path, id, 'pages'))..createSync(recursive: true);
  for (var i = 1; i <= pages; i++) {
    File(p.join(dir.path, 'page_${i.toString().padLeft(3, '0')}.jpg')).writeAsBytesSync(fakeDocumentJpeg(width: 60, height: 80));
  }
  await db.upsertDocument(
    DocumentsCompanion(
      id: Value(id),
      name: Value(name),
      format: const Value(SaveFormat.pdf),
      dirPath: Value('library/$id'),
      pageCount: Value(pages),
      sizeBytes: const Value(1000),
      createdAt: Value(created),
      updatedAt: Value(created),
    ),
  );
}

void main() {
  testWidgets('select documents in the library and merge them into the editor', (tester) async {
    final (app, db, paths) = await buildTestApp(prefs: {'settings.language': 'en'});
    addTearDown(db.close);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await _insertWithPages(db, paths, 'a', 'Bank statement', DateTime(2026, 10, 1), 2);
      await _insertWithPages(db, paths, 'b', 'Birth certificate', DateTime(2026, 10, 5), 1);
    });

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    // Merge button is disabled until two documents are picked.
    await tester.tap(find.byTooltip('Merge documents'));
    await tester.pumpAndSettle();
    expect(find.text('Select documents to merge'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Merge')).enabled, isFalse);

    // Pick the older document first so it comes first in the merged result.
    await tester.tap(find.text('Bank statement'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.text('Birth certificate'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Merge')).enabled, isTrue);

    // The merge copies files and hops between async zones; pump between
    // real waits so every continuation gets to run.
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
      for (var i = 0; i < 30 && find.text('Edit pages').evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();

    // The editor opens with all three pages, the sources untouched.
    expect(find.text('Edit pages'), findsOneWidget);
    expect(find.text('3 pages'), findsOneWidget);
    expect(await db.getDocument('a'), isNotNull);
    expect(await db.getDocument('b'), isNotNull);
    expect(Directory(p.join(paths.libraryDir.path, 'a', 'pages')).listSync().length, 2);

    // Saving offers a "Merged-…" name by default.
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    final nameField = tester.widget<TextField>(find.byType(TextField).first);
    expect(nameField.controller!.text, startsWith('Merged-'));
    await unmountApp(tester);
  });

  testWidgets('long press starts selection and close leaves it', (tester) async {
    final (app, db, paths) = await buildTestApp(prefs: {'settings.language': 'en'});
    addTearDown(db.close);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await _insertWithPages(db, paths, 'a', 'Bank statement', DateTime(2026, 10, 1), 1);
      await _insertWithPages(db, paths, 'b', 'Birth certificate', DateTime(2026, 10, 5), 1);
    });

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Bank statement'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('My documents'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
    await unmountApp(tester);
  });
}
