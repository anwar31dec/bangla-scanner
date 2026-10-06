import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/app_paths.dart';
import 'core/storage/startup_cleanup.dart';
import 'features/settings/application/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load preferences before the first frame so the saved language and theme
  // are applied immediately.
  final prefs = await SharedPreferences.getInstance();
  await initializeDateFormatting('bn');
  await initializeDateFormatting('en');

  // Clear temp files left by a previous session (before any new draft).
  try {
    await runStartupCleanup(await AppPaths.resolve());
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BanglaScannerApp(),
    ),
  );
}
