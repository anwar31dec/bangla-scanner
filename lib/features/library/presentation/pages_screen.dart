import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/progress_overlay.dart';
import '../../export/presentation/save_sheet.dart';
import '../application/library_providers.dart';
import '../data/document_repository.dart';

/// Reorder or remove the pages of a saved document without re-scanning or
/// re-processing anything: the page images are kept as they are and the
/// PDF is rebuilt.
class PagesScreen extends ConsumerStatefulWidget {
  const PagesScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends ConsumerState<PagesScreen> {
  /// Working order; null until the pages have loaded.
  List<File>? _order;
  List<File>? _original;
  bool _busy = false;

  bool get _changed {
    final a = _order, b = _original;
    if (a == null || b == null) return false;
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i].path != b[i].path) return true;
    }
    return false;
  }

  Future<void> _apply() async {
    final l10n = context.l10n;
    final doc = ref.read(documentProvider(widget.documentId)).value;
    final order = _order;
    if (doc == null || order == null || order.isEmpty) return;

    String? password;
    if (doc.isProtected) {
      password = await showPasswordDialog(
        context,
        title: l10n.enterPdfPassword,
        body: l10n.enterPdfPasswordBody,
        minLength: minPdfPasswordLength,
      );
      if (password == null || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.rewritePages(doc, order, password: password);
      // Files were rewritten under the same paths; drop cached images.
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      if (!mounted) return;
      showSnack(context, l10n.pagesUpdated);
      context.pop();
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
    final pagesAsync = ref.watch(documentPagesProvider(widget.documentId));
    if (_order == null && pagesAsync.hasValue) {
      _original = List.of(pagesAsync.value!);
      _order = List.of(pagesAsync.value!);
    }
    final order = _order;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(l10n.pagesTitle)),
          body: order == null
              ? const Center(child: CircularProgressIndicator())
              : order.isEmpty
                  ? Center(child: EmptyState(icon: Icons.broken_image_outlined, title: l10n.documentMissing))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(l10n.pagesHint, style: theme.textTheme.bodySmall),
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: order.length,
                            onReorderItem: (oldIndex, newIndex) => setState(() => order.insert(newIndex, order.removeAt(oldIndex))),
                            itemBuilder: (context, index) => _PageRow(
                              key: ValueKey(order[index].path),
                              file: order[index],
                              index: index,
                              canDelete: order.length > 1,
                              onDelete: () => setState(() => order.removeAt(index)),
                            ),
                          ),
                        ),
                      ],
                    ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _busy || !_changed ? null : _apply,
                icon: const Icon(Icons.check),
                label: Text(l10n.apply),
              ),
            ),
          ),
        ),
        if (_busy) ProgressOverlay(message: l10n.saving),
      ],
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({super.key, required this.file, required this.index, required this.canDelete, required this.onDelete});

  final File file;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      cacheWidth: 220,
                      errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(l10n.pageLabel(index + 1), style: theme.textTheme.titleMedium)),
              IconButton.filledTonal(
                tooltip: l10n.delete,
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.delete_outline),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.drag_handle, size: 28)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
