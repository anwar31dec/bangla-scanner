import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_paths.dart';

/// Removes leftovers from interrupted sessions: old drafts, shared copies
/// and half-written documents (`*.staging`). Safe to run on every start.
Future<void> runStartupCleanup(AppPaths paths) async {
  Future<void> wipe(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  await wipe(paths.workDir);
  await wipe(paths.shareDir);
  await wipe(paths.backupDir);
  await wipe(paths.receivedDir);
  try {
    if (await paths.libraryDir.exists()) {
      await for (final entry in paths.libraryDir.list()) {
        if (entry is Directory && p.basename(entry.path).endsWith('.staging')) await wipe(entry);
      }
    }
  } catch (_) {}
}
