import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('home screen is in Bangla by default', (tester) async {
    final (app, db, _) = await buildTestApp();
    addTearDown(db.close);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('বাংলা স্ক্যানার'), findsOneWidget);
    expect(find.text('স্ক্যান'), findsOneWidget);
    expect(find.text('ফ্ল্যাশ স্ক্যান'), findsOneWidget);
    expect(find.text('ইমপোর্ট'), findsOneWidget);
    expect(find.text('আইডি কার্ড'), findsOneWidget);
    expect(find.text('এখনো কোনো ডকুমেন্ট নেই'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('English can be chosen in settings', (tester) async {
    final (app, db, _) = await buildTestApp();
    addTearDown(db.close);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Import'), findsOneWidget);
    await unmountApp(tester);
  });
}
