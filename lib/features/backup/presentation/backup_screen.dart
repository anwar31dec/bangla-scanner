import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/progress_dialog.dart';
import '../../export/data/share_service.dart';
import '../../library/application/library_providers.dart';
import '../data/backup_service.dart';

/// Settings → Backup & restore: export the library as a zip to Downloads /
/// Files (or share it), and import such a zip again.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _createBackup() async {
    final l10n = context.l10n;
    final docs = ref.read(allDocumentsProvider).value;
    if (docs != null && docs.isEmpty) {
      showSnack(context, l10n.backupEmpty);
      return;
    }
    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      if (!mounted) return;
      final zip = await runWithProgressDialog<File>(
        context,
        message: l10n.backupCreating,
        progressText: l10n.backupProgress,
        task: (report) => service.createBackup(onProgress: report),
      );
      if (!mounted) return;
      await _offerBackup(zip);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The zip is ready: save it to the phone or share it.
  Future<void> _offerBackup(File zip) async {
    final l10n = context.l10n;
    final locale = context.localeTag;
    final size = Formatters.fileSize(await zip.length(), locale);
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l10n.backupReady(size), style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(l10n.backupSave),
              subtitle: Text(Platform.isAndroid ? l10n.backupSaveHintAndroid : l10n.backupSaveHintIos),
              onTap: () => Navigator.pop(context, 'save'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(l10n.backupShare),
              subtitle: Text(l10n.backupShareHint),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final share = await ref.read(shareServiceProvider.future);
    if (!mounted) return;
    if (choice == 'share') {
      await share.shareFiles([zip]);
      return;
    }
    if (!await PermissionService.ensureStorageForDownloads(context)) return;
    final result = await share.saveFilesToDevice([zip]);
    if (!mounted) return;
    switch (result) {
      case SaveDestination.downloads:
        showSnack(context, l10n.savedToDownloads);
      case SaveDestination.files:
        showSnack(context, l10n.savedToFiles);
      case SaveDestination.cancelled:
        break;
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['zip']);
      final path = picked.isEmpty ? null : picked.first.path;
      if (path == null || !mounted) return;

      final service = await ref.read(backupServiceProvider.future);
      final manifest = await service.inspect(path);
      if (!mounted) return;
      final ok = await showConfirmDialog(
        context,
        title: l10n.backupRestoreConfirmTitle,
        body: l10n.backupRestoreConfirmBody(
          manifest.documents.length,
          Formatters.dateTime(manifest.createdAt, context.localeTag),
        ),
        confirmLabel: l10n.restore,
      );
      if (!ok || !mounted) return;

      final summary = await runWithProgressDialog(
        context,
        message: l10n.backupRestoring,
        progressText: l10n.backupProgress,
        task: (report) => service.restore(path, onProgress: report),
      );
      if (!mounted) return;
      // Restored thumbnails may reuse paths of documents deleted earlier.
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      showSnack(context, l10n.backupRestored(summary.added, summary.skipped));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final docs = ref.watch(allDocumentsProvider).value;
    final totalSize = docs?.fold<int>(0, (sum, d) => sum + d.sizeBytes);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.backupIntro, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ActionCard(
            icon: Icons.archive_outlined,
            title: l10n.backupCreate,
            subtitle: docs == null || totalSize == null
                ? l10n.backupCreateHint
                : '${l10n.backupCreateHint}\n${l10n.backupStats(docs.length, Formatters.fileSize(totalSize, context.localeTag))}',
            onTap: _busy ? null : _createBackup,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.unarchive_outlined,
            title: l10n.backupRestore,
            subtitle: l10n.backupRestoreHint,
            onTap: _busy ? null : _restore,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle)),
        trailing: const Icon(Icons.chevron_right),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
