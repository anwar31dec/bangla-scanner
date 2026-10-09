import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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
  await _initFirebase();

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

/// Firebase is configured for Android only (android/app/google-services.json).
/// No options are passed, so the native SDK picks the client matching the
/// running package and dev crashes land under the dev app, not prod.
Future<void> _initFirebase() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    // Crash reporting must never keep the scanner from opening.
    debugPrint('Firebase init failed: $e');
  }
}
