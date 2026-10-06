import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/dialogs.dart';
import '../application/draft_controller.dart';
import '../data/scanner_service.dart';

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

  /// "Import from Gallery": pick photos, then open the editor.
  static Future<void> importNew(BuildContext context, WidgetRef ref) async {
    final paths = await pickImages(context, ref);
    if (paths == null || !context.mounted) return;
    await ref.read(draftProvider.notifier).startNew(paths);
    if (context.mounted) context.push(Routes.editor);
  }

  /// Adds pages to the open draft (from the editor).
  static Future<void> addPages(BuildContext context, WidgetRef ref, {required bool fromCamera}) async {
    final paths = fromCamera ? await scanPages(context, ref) : await pickImages(context, ref);
    if (paths == null) return;
    await ref.read(draftProvider.notifier).addPages(paths);
    if (fromCamera) await ref.read(scannerServiceProvider).cleanCache();
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
