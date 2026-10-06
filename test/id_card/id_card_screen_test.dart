import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_app.dart';

void main() {
  testWidgets('ID card flow starts with the front side; back is locked', (tester) async {
    final (app, db, _) = await buildTestApp(prefs: {'settings.language': 'en'});
    addTearDown(db.close);
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ID Card'));
    await tester.pumpAndSettle();

    expect(find.textContaining('FRONT side'), findsOneWidget);
    final scanButtons = find.widgetWithText(FilledButton, 'Scan');
    expect(scanButtons, findsNWidgets(2));
    expect(tester.widget<FilledButton>(scanButtons.first).onPressed, isNotNull);
    expect(tester.widget<FilledButton>(scanButtons.last).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Create A4 page')).onPressed, isNull);
    await unmountApp(tester);
  });
}
