import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/dialogs.dart';
import '../../export/data/share_service.dart';
import '../../scan/application/draft_controller.dart';
import '../data/document_repository.dart';

/// Actions on a saved document, shared by the library list and the
/// document screen.
class DocumentActions {
  DocumentActions._();

  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  static Future<void> share(BuildContext context, WidgetRef ref, DocumentRow doc) async {
    final origin = _origin(context);
    try {
      final service = await ref.read(shareServiceProvider.future);
      await service.shareDocument(doc, origin: origin);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  static Future<void> saveToDevice(BuildContext context, WidgetRef ref, DocumentRow doc) async {
    final l10n = context.l10n;
    if (!await PermissionService.ensureStorageForDownloads(context)) return;
    try {
      final service = await ref.read(shareServiceProvider.future);
      final result = await service.saveDocumentToDevice(doc);
      if (!context.mounted) return;
      switch (result) {
        case SaveDestination.downloads:
          showSnack(context, l10n.savedToDownloads);
        case SaveDestination.files:
          showSnack(context, l10n.savedToFiles);
        case SaveDestination.cancelled:
          break;
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  static Future<void> rename(BuildContext context, WidgetRef ref, DocumentRow doc) async {
    final l10n = context.l10n;
    final name = await showTextInputDialog(context, title: l10n.renameTitle, initialValue: doc.name, label: l10n.fileName);
    if (name == null || name == doc.name) return;
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.rename(doc.id, name);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  /// Asks for confirmation, then deletes. Returns true when deleted.
  static Future<bool> delete(BuildContext context, WidgetRef ref, DocumentRow doc) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteDocTitle,
      body: l10n.deleteDocBody(doc.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return false;
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.delete(doc);
      if (context.mounted) showSnack(context, l10n.deleted);
      return true;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return false;
    }
  }

  /// Loads the pages of [docs] (in that order) into the editor as a new
  /// draft, so they can be reordered and saved as one document. Documents
  /// whose files are missing are skipped. Returns true when the editor was
  /// opened.
  static Future<bool> merge(BuildContext context, WidgetRef ref, List<DocumentRow> docs) async {
    final l10n = context.l10n;
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      final paths = <String>[];
      var skipped = 0;
      for (final doc in docs) {
        final pages = await repo.pagesOf(doc);
        if (pages.isEmpty) {
          skipped++;
          continue;
        }
        paths.addAll(pages.map((f) => f.path));
      }
      if (!context.mounted) return false;
      if (paths.isEmpty) {
        showSnack(context, l10n.documentMissing);
        return false;
      }
      await ref.read(draftProvider.notifier).startMerged(
            paths,
            suggestedName: Formatters.defaultMergedName(DateTime.now()),
          );
      if (!context.mounted) return false;
      if (skipped > 0) showSnack(context, l10n.mergeSkippedMissing(skipped));
      context.push(Routes.editor);
      return true;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return false;
    }
  }

  /// Loads the document's pages into the editor.
  static Future<void> edit(BuildContext context, WidgetRef ref, DocumentRow doc) async {
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      final pages = await repo.pagesOf(doc);
      if (pages.isEmpty) {
        if (context.mounted) showSnack(context, context.l10n.documentMissing);
        return;
      }
      await ref.read(draftProvider.notifier).startFromDocument(doc, [for (final f in pages) f.path]);
      if (context.mounted) context.push(Routes.editor);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
