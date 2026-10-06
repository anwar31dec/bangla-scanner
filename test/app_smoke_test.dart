import 'package:banglascanner/app.dart';
import 'package:banglascanner/features/settings/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _app({Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await initializeDateFormatting('bn');
  await initializeDateFormatting('en');
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
    child: const BanglaScannerApp(),
  );
}

void main() {
  testWidgets('home screen is in Bangla by default', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text('বাংলা স্ক্যানার'), findsOneWidget);
    expect(find.text('স্ক্যান'), findsOneWidget);
    expect(find.text('গ্যালারি থেকে আনুন'), findsOneWidget);
    expect(find.text('আইডি কার্ড'), findsOneWidget);
  });

  testWidgets('English can be chosen in settings', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Import from Gallery'), findsOneWidget);
  });
}
