import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/progress_overlay.dart';
import '../../export/data/export_service.dart';
import '../../export/presentation/save_sheet.dart';
import '../../scan/application/draft_controller.dart';
import '../../scan/data/draft_document.dart';
import '../../scan/presentation/scan_actions.dart';
import 'page_preview.dart';

/// Shows the pages of the current draft: reorder by drag and drop, open a
/// page to crop/rotate/filter, delete, add more pages, and save.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _busy = false;
  String? _progressText;
  double? _progress;

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    final draft = ref.read(draftProvider);
    if (draft == null || draft.pages.isEmpty) return true;
    return showConfirmDialog(
      context,
      title: l10n.editorDiscardTitle,
      body: l10n.editorDiscardBody,
      confirmLabel: l10n.discard,
      destructive: true,
    );
  }

  Future<void> _leave() async {
    if (!await _confirmDiscard()) return;
    await ref.read(draftProvider.notifier).discard();
    if (mounted) context.pop();
  }

  Future<void> _addPages() async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<PageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(l10n.addFromCamera),
              onTap: () => Navigator.pop(context, PageSource.scanner),
            ),
            ListTile(
              leading: const Icon(Icons.flash_on_outlined),
              title: Text(l10n.addFromFlashCamera),
              onTap: () => Navigator.pop(context, PageSource.flashCamera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.addFromGallery),
              onTap: () => Navigator.pop(context, PageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.addFromPdf),
              onTap: () => Navigator.pop(context, PageSource.pdf),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ScanActions.addPages(context, ref, source: source);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final draft = ref.read(draftProvider);
    if (draft == null || draft.pages.isEmpty) return;

    final options = await showSaveSheet(
      context,
      initialName: draft.existingName ?? draft.suggestedName ?? Formatters.defaultScanName(DateTime.now()),
      initialFormat: draft.existingFormat,
      initialProtected: draft.existingIsProtected,
    );
    if (options == null || !mounted) return;

    setState(() {
      _busy = true;
      _progress = 0;
      _progressText = l10n.saving;
    });
    try {
      final service = await ref.read(exportServiceProvider.future);
      final doc = await service.save(
        draft: draft,
        name: options.name,
        format: options.format,
        quality: options.quality,
        pageSize: options.pageSize,
        password: options.password,
        ocrLanguage: options.ocrLanguage,
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _progress = done / total;
            _progressText = done < total ? l10n.savingProgress(done + 1, total) : l10n.saving;
          });
        },
        onOcrProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _progress = done / total;
            _progressText = done < total ? l10n.ocrRecognizing(done + 1, total) : l10n.saving;
          });
        },
      );
      await ref.read(draftProvider.notifier).discard();
      if (!mounted) return;
      showSnack(context, l10n.saved);
      if (draft.existingDocumentId != null) {
        // The document's files were rewritten under the same paths; drop
        // cached thumbnails/pages so the new version is shown.
        PaintingBinding.instance.imageCache
          ..clear()
          ..clearLiveImages();
        context.pop();
      } else {
        context.pushReplacement(Routes.documentPath(doc.id));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _deletePage(DraftPage page) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.deletePageTitle,
      body: l10n.deletePageBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (ok) ref.read(draftProvider.notifier).deletePage(page.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = ref.watch(draftProvider);
    final pages = draft?.pages ?? const <DraftPage>[];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _leave();
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: IconButton(icon: const Icon(Icons.close), tooltip: l10n.close, onPressed: _busy ? null : _leave),
              title: Text(l10n.editorTitle),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(child: Text(l10n.editorPages(pages.length))),
                ),
              ],
            ),
            body: pages.isEmpty
                ? Center(child: EmptyState(icon: Icons.note_add_outlined, title: l10n.editorEmpty))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(l10n.editorDragHint, style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: pages.length,
                          onReorderItem: ref.read(draftProvider.notifier).reorder,
                          itemBuilder: (context, index) {
                            final page = pages[index];
                            return _PageCard(
                              key: ValueKey(page.id),
                              page: page,
                              index: index,
                              onOpen: () => context.push(Routes.pageEditPath(index)),
                              onRotate: () => ref.read(draftProvider.notifier).rotate(page.id),
                              onDelete: () => _deletePage(page),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _addPages,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.editorAddPages),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy || pages.isEmpty ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(l10n.editorSave),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_busy && _progressText != null) ProgressOverlay(message: _progressText!, progress: _progress),
        ],
      ),
    );
  }
}

/// One page row: thumbnail, page number, quick actions and drag handle.
class _PageCard extends StatelessWidget {
  const _PageCard({
    super.key,
    required this.page,
    required this.index,
    required this.onOpen,
    required this.onRotate,
    required this.onDelete,
  });

  final DraftPage page;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onRotate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 128,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: PagePreview(page: page, cacheWidth: 300),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.pageLabel(index + 1), style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(l10n.filterLabel(page.filter), style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton.filledTonal(tooltip: l10n.rotate, onPressed: onRotate, icon: const Icon(Icons.rotate_right)),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(tooltip: l10n.delete, onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
                        ],
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
