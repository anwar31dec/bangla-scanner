import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_app.dart';

Future<void> _insert(AppDatabase db, String id, String name, DateTime created) => db.upsertDocument(
      DocumentsCompanion(
        id: Value(id),
        name: Value(name),
        format: const Value(SaveFormat.pdf),
        dirPath: Value('library/$id'),
        pageCount: const Value(2),
        sizeBytes: const Value(150000),
        createdAt: Value(created),
        updatedAt: Value(created),
      ),
    );

void main() {
  testWidgets('recent list, search and delete with confirmation', (tester) async {
    final (app, db, _) = await buildTestApp(prefs: {'settings.language': 'en'});
    addTearDown(db.close);
    await tester.runAsync(() async {
      await _insert(db, 'a', 'Bank statement', DateTime(2026, 10, 1));
      await _insert(db, 'b', 'Birth certificate', DateTime(2026, 10, 5));
    });

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.text('Bank statement'), findsOneWidget);
    expect(find.text('Birth certificate'), findsOneWidget);

    // Open the library and search.
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('My documents'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'birth');
    await tester.pumpAndSettle();
    expect(find.text('Bank statement'), findsNothing);
    expect(find.text('Birth certificate'), findsOneWidget);
    expect(find.textContaining('2 pages'), findsOneWidget);

    // Delete it through the menu; cancel first, then confirm.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete document?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Birth certificate'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('Birth certificate'), findsNothing);
    expect(find.text('No document found with this name.'), findsOneWidget);
    await unmountApp(tester);
  });
}
