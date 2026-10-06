import 'dart:io';

import 'package:banglascanner/app.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/core/storage/storage_providers.dart';
import 'package:banglascanner/features/settings/application/settings_controller.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the full app with an in-memory database and temp folders.
Future<(Widget, AppDatabase, AppPaths)> buildTestApp({Map<String, Object> prefs = const {}}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await initializeDateFormatting('bn');
  await initializeDateFormatting('en');
  final root = Directory.systemTemp.createTempSync('bs_app');
  final paths = AppPaths(Directory(p.join(root.path, 'docs'))..createSync(), Directory(p.join(root.path, 'tmp'))..createSync());
  final db = AppDatabase(NativeDatabase.memory());
  final app = ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      appDatabaseProvider.overrideWithValue(db),
      appPathsProvider.overrideWith((ref) async => paths),
    ],
    child: const BanglaScannerApp(),
  );
  return (app, db, paths);
}

/// Unmounts the app and flushes drift's stream-cleanup timers, which would
/// otherwise fail the test with "A Timer is still pending".
Future<void> unmountApp(dynamic tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
}
