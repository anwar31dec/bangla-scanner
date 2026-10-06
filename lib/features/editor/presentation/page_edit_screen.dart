import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../../../core/widgets/dialogs.dart';
import '../../export/data/image_processing.dart';
import '../../scan/application/draft_controller.dart';
import '../../scan/data/draft_document.dart';
import 'page_preview.dart';

/// Edits one page: crop, rotate, filter, delete. Swipe to move between
/// pages.
class PageEditScreen extends ConsumerStatefulWidget {
  const PageEditScreen({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  ConsumerState<PageEditScreen> createState() => _PageEditScreenState();
}

class _PageEditScreenState extends ConsumerState<PageEditScreen> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _crop(DraftPage page) async {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    setState(() => _busy = true);
    try {
      var source = page.imagePath;
      // The cropper does not know about our pending rotation, so bake it in
      // first; otherwise the user would crop a sideways page.
      if (page.quarterTurns != 0) {
        final bytes = await File(source).readAsBytes();
        final turns = page.quarterTurns;
        final rotated = await Isolate.run(() => ImageProcessing.rotateJpeg(bytes, turns));
        source = p.join(p.dirname(page.imagePath), 'rot_${DateTime.now().microsecondsSinceEpoch}.jpg');
        await File(source).writeAsBytes(rotated, flush: true);
      }
      final cropped = await ImageCropper().cropImage(
        sourcePath: source,
        compressQuality: 95,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: l10n.crop,
            toolbarColor: scheme.surface,
            toolbarWidgetColor: scheme.onSurface,
            activeControlsWidgetColor: scheme.primary,
            lockAspectRatio: false,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: l10n.crop,
            doneButtonTitle: l10n.done,
            cancelButtonTitle: l10n.cancel,
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );
      // Cancelled crops leave the page unchanged.
      if (cropped != null) await ref.read(draftProvider.notifier).replaceImage(page.id, cropped.path);
    } catch (_) {
      if (mounted) showSnack(context, l10n.cropFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(DraftPage page, int total) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.deletePageTitle,
      body: l10n.deletePageBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok) return;
    ref.read(draftProvider.notifier).deletePage(page.id);
    if (total <= 1 && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = ref.watch(draftProvider)?.pages ?? const <DraftPage>[];
    if (pages.isEmpty) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l10n.editorEmpty)));
    }
    final index = _index.clamp(0, pages.length - 1);
    final page = pages[index];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pageEditTitle(index + 1, pages.length))),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(child: PagePreview(page: pages[i])),
                  ),
                ),
                if (_busy) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          // Filter choices.
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in PageFilter.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(l10n.filterLabel(f)),
                      selected: page.filter == f,
                      onSelected: (_) => ref.read(draftProvider.notifier).setFilter(page.id, f),
                    ),
                  ),
              ],
            ),
          ),
          if (pages.length > 1)
            TextButton.icon(
              onPressed: () {
                ref.read(draftProvider.notifier).applyFilterToAll(page.filter);
                showSnack(context, l10n.appliedToAll);
              },
              icon: const Icon(Icons.done_all),
              label: Text(l10n.applyToAllPages),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: theme.colorScheme.surfaceContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolButton(icon: Icons.crop, label: l10n.crop, onPressed: _busy ? null : () => _crop(page)),
              _ToolButton(
                icon: Icons.rotate_right,
                label: l10n.rotate,
                onPressed: _busy ? null : () => ref.read(draftProvider.notifier).rotate(page.id),
              ),
              _ToolButton(
                icon: Icons.delete_outline,
                label: l10n.delete,
                onPressed: _busy ? null : () => _delete(page, pages.length),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 88, minHeight: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 28), const SizedBox(height: 4), Text(label)],
        ),
      ),
    );
  }
}
