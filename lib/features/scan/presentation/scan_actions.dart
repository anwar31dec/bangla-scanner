import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/l10n/l10n.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/dialogs.dart';
import '../application/draft_controller.dart';
import '../data/scanner_service.dart';
import 'flash_camera_screen.dart';

/// Where new pages come from.
enum PageSource {
  /// The native document scanner.
  scanner,

  /// The in-app camera whose flash fires only when a photo is taken.
  flashCamera,
  gallery,
}

/// UI-level orchestration of scanning/importing: permissions, the native
/// scanner, error messages and navigation to the editor.
class ScanActions {
  ScanActions._();

  /// Big "Scan" button: scan pages, then open the editor.
  static Future<void> scanNew(BuildContext context, WidgetRef ref) async {
    final paths = await scanPages(context, ref);
    if (paths == null || !context.mounted) return;
    await ref.read(draftProvider.notifier).startNew(paths);
    await ref.read(scannerServiceProvider).cleanCache();
    if (context.mounted) context.push(Routes.editor);
  }

  /// "Flash Scan": take pages with the in-app camera, then open the editor.
  static Future<void> flashScanNew(BuildContext context, WidgetRef ref) async {
    final paths = await captureWithFlash(context, ref);
    if (paths == null || !context.mounted) return;
    await ref.read(draftProvider.notifier).startNew(paths);
    _deleteCaptureDir(paths);
    if (context.mounted) context.push(Routes.editor);
  }

  /// "Import from Gallery": pick photos, then open the editor.
  static Future<void> importNew(BuildContext context, WidgetRef ref) async {
    final paths = await pickImages(context, ref);
    if (paths == null || !context.mounted) return;
    await ref.read(draftProvider.notifier).startNew(paths);
    if (context.mounted) context.push(Routes.editor);
  }

  /// Adds pages to the open draft (from the editor).
  static Future<void> addPages(BuildContext context, WidgetRef ref, {required PageSource source}) async {
    final paths = await switch (source) {
      PageSource.scanner => scanPages(context, ref),
      PageSource.flashCamera => captureWithFlash(context, ref),
      PageSource.gallery => pickImages(context, ref),
    };
    if (paths == null) return;
    await ref.read(draftProvider.notifier).addPages(paths);
    switch (source) {
      case PageSource.scanner:
        await ref.read(scannerServiceProvider).cleanCache();
      case PageSource.flashCamera:
        _deleteCaptureDir(paths);
      case PageSource.gallery:
    }
  }

  /// Runs the native scanner. Returns null when cancelled or failed (the
  /// user has already been told why).
  static Future<List<String>?> scanPages(BuildContext context, WidgetRef ref, {int maxPages = 50}) async {
    final l10n = context.l10n;
    if (!await PermissionService.ensureCamera(context)) return null;
    try {
      final paths = await ref.read(scannerServiceProvider).scan(maxPages: maxPages);
      if (paths == null || paths.isEmpty) {
        if (context.mounted) showSnack(context, l10n.scanCancelled);
        return null;
      }
      return paths;
    } on ScannerPermissionDenied {
      if (context.mounted) await PermissionService.showPermissionDeniedDialog(context);
    } on PlatformException catch (_) {
      if (context.mounted) showSnack(context, l10n.scanFailed);
    } catch (_) {
      if (context.mounted) showSnack(context, l10n.scanFailed);
    }
    return null;
  }

  /// Opens the in-app camera, whose flash fires only when a photo is taken.
  /// Returns the pages (in a folder of their own, see [_deleteCaptureDir]),
  /// or null when cancelled.
  static Future<List<String>?> captureWithFlash(BuildContext context, WidgetRef ref) async {
    if (!await PermissionService.ensureCamera(context)) return null;
    final Directory dir;
    try {
      final paths = await ref.read(appPathsProvider.future);
      dir = Directory(p.join(paths.workDir.path, 'camera_${DateTime.now().microsecondsSinceEpoch}'));
      await dir.create(recursive: true);
    } catch (e) {
      if (context.mounted) showError(context, e);
      return null;
    }
    if (!context.mounted) return null;
    final pages = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => FlashCameraScreen(outputDir: dir)),
    );
    if (pages == null || pages.isEmpty) {
      dir.delete(recursive: true).ignore();
      return null;
    }
    return pages;
  }

  /// Removes the folder [captureWithFlash] wrote its pages to, once they
  /// have been copied into the draft.
  static void _deleteCaptureDir(List<String> paths) => File(paths.first).parent.delete(recursive: true).ignore();

  /// Opens the gallery picker. Returns null when cancelled or failed.
  static Future<List<String>?> pickImages(BuildContext context, WidgetRef ref, {bool single = false}) async {
    final l10n = context.l10n;
    try {
      final paths = await ref.read(scannerServiceProvider).pickImages(limit: single ? 1 : null);
      return paths.isEmpty ? null : paths;
    } on PlatformException catch (e) {
      if (!context.mounted) return null;
      if (e.code.contains('denied')) {
        await PermissionService.showPermissionDeniedDialog(context);
      } else {
        showSnack(context, l10n.importFailed);
      }
    } catch (_) {
      if (context.mounted) showSnack(context, l10n.importFailed);
    }
    return null;
  }
}
