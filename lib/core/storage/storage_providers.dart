import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'app_paths.dart';

/// The single database instance for the app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Resolved app directories (async because path_provider is async).
final appPathsProvider = FutureProvider<AppPaths>((ref) => AppPaths.resolve());
