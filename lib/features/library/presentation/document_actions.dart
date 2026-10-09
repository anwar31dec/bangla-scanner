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
import '../application/library_providers.dart';
import '../data/document_repository.dart';

/// Actions on saved documents and folders, shared by the library list, the
/// document screen and the home screen.
class DocumentActions {
  DocumentActions._();

  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  static Future<void> share(BuildContext context, WidgetRef ref, DocumentRow doc) => shareMany(context, ref, [doc]);

  /// Shares the files of several documents in one go.
  static Future<void> shareMany(BuildContext context, WidgetRef ref, List<DocumentRow> docs) async {
    if (docs.isEmpty) return;
    final origin = _origin(context);
    try {
      final service = await ref.read(shareServiceProvider.future);
      await service.shareDocuments(docs, origin: origin);
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

  static Future<void> toggleFavorite(BuildContext context, WidgetRef ref, DocumentRow doc) =>
      setFavorite(context, ref, [doc], !doc.isFavorite);

  static Future<void> setFavorite(BuildContext context, WidgetRef ref, List<DocumentRow> docs, bool favorite) async {
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      for (final doc in docs) {
        if (doc.isFavorite != favorite) await repo.setFavorite(doc.id, favorite);
      }
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

  /// Deletes several documents after one confirmation. Returns true when
  /// they were deleted.
  static Future<bool> deleteMany(BuildContext context, WidgetRef ref, List<DocumentRow> docs) async {
    if (docs.isEmpty) return false;
    if (docs.length == 1) return delete(context, ref, docs.first);
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteSelectedTitle(docs.length),
      body: l10n.deleteSelectedBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return false;
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.deleteAll(docs);
      if (context.mounted) showSnack(context, l10n.deletedCount(docs.length));
      return true;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return false;
    }
  }

  /// Lets the user pick a folder (or none, or a new one) for [docs].
  /// Returns true when they were moved.
  static Future<bool> moveToFolder(BuildContext context, WidgetRef ref, List<DocumentRow> docs) async {
    if (docs.isEmpty) return false;
    final l10n = context.l10n;
    final choice = await showModalBottomSheet<_FolderChoice>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _FolderPicker(current: docs.length == 1 ? docs.first.folderId : null),
    );
    if (choice == null || !context.mounted) return false;
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      if (!context.mounted) return false;
      FolderRow? target;
      switch (choice) {
        case _NoFolder():
          break;
        case _ExistingFolder(:final folder):
          target = folder;
        case _NewFolder():
          target = await createFolder(context, ref);
          if (target == null) return false;
      }
      await repo.moveToFolder([for (final d in docs) d.id], target?.id);
      if (context.mounted) showSnack(context, target == null ? l10n.removedFromFolder : l10n.movedToFolder(target.name));
      return true;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return false;
    }
  }

  /// Asks for a name and creates the folder. Returns null when cancelled.
  static Future<FolderRow?> createFolder(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showTextInputDialog(context, title: l10n.newFolder, initialValue: '', label: l10n.folderName);
    if (name == null) return null;
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      final folder = await repo.createFolder(name);
      if (context.mounted) showSnack(context, l10n.folderCreated);
      return folder;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return null;
    }
  }

  static Future<void> renameFolder(BuildContext context, WidgetRef ref, FolderRow folder) async {
    final l10n = context.l10n;
    final name = await showTextInputDialog(context, title: l10n.renameFolder, initialValue: folder.name, label: l10n.folderName);
    if (name == null || name == folder.name) return;
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.renameFolder(folder.id, name);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  /// Deletes the folder (its documents stay). Returns true when deleted.
  static Future<bool> deleteFolder(BuildContext context, WidgetRef ref, FolderRow folder) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteFolderTitle,
      body: l10n.deleteFolderBody(folder.name),
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return false;
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.deleteFolder(folder.id);
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

  /// Opens the page order / delete screen of a saved document.
  static void reorderPages(BuildContext context, DocumentRow doc) => context.push(Routes.pagesPath(doc.id));
}

sealed class _FolderChoice {
  const _FolderChoice();
}

class _NoFolder extends _FolderChoice {
  const _NoFolder();
}

class _NewFolder extends _FolderChoice {
  const _NewFolder();
}

class _ExistingFolder extends _FolderChoice {
  const _ExistingFolder(this.folder);
  final FolderRow folder;
}

/// Bottom sheet listing the folders to move documents into.
class _FolderPicker extends ConsumerWidget {
  const _FolderPicker({this.current});

  /// Folder the document is in now (single document only).
  final String? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider).value ?? const <FolderRow>[];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(l10n.moveToFolder, style: theme.textTheme.titleLarge)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_off_outlined),
                  title: Text(l10n.noFolder),
                  trailing: current == null ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, const _NoFolder()),
                ),
                for (final f in folders)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(f.name),
                    trailing: current == f.id ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(context, _ExistingFolder(f)),
                  ),
                ListTile(
                  leading: const Icon(Icons.create_new_folder_outlined),
                  title: Text(l10n.newFolder),
                  onTap: () => Navigator.pop(context, const _NewFolder()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
