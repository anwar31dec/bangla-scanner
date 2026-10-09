import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

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
import '../../stamps/data/stamp_compositor.dart';
import '../../stamps/presentation/stamp_picker_sheet.dart';
import '../../stamps/presentation/stamp_placement_screen.dart';
import 'page_preview.dart';

/// Top-level on purpose: a closure created inside the State would carry the
/// State with it, and that cannot be sent to another isolate.
Future<Uint8List> _rotateInBackground(Uint8List bytes, int quarterTurns) =>
    Isolate.run(() => ImageProcessing.rotateJpeg(bytes, quarterTurns));

Future<Uint8List> _stampInBackground(
  Uint8List page,
  Uint8List stamp,
  StampPlacement placement,
  int quarterTurns,
  PageFilter filter,
  PageAdjustments adjustments,
) =>
    Isolate.run(
      () => StampCompositor.apply(
        page,
        stamp,
        placement: placement,
        quarterTurns: quarterTurns,
        filter: filter,
        adjustments: adjustments,
      ),
    );

/// Edits one page: crop, rotate, filter, adjust (strength, brightness,
/// contrast), book split, delete. Swipe to move between pages.
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

  /// Shows the adjustment sliders instead of the filter strip.
  bool _adjusting = false;

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
        final rotated = await _rotateInBackground(bytes, turns);
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

  /// Signature or stamp: choose one, place it, then burn it into the page
  /// together with the pending rotation, filter and adjustments.
  Future<void> _sign(DraftPage page) async {
    final l10n = context.l10n;
    final stamp = await showStampPicker(context);
    if (stamp == null || !mounted) return;
    final placement = await Navigator.of(context).push<StampPlacement>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => StampPlacementScreen(page: page, stampPng: stamp),
      ),
    );
    if (placement == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = await File(page.imagePath).readAsBytes();
      final flattened = await _stampInBackground(
        bytes,
        stamp,
        placement,
        page.quarterTurns,
        page.filter,
        page.adjustments,
      );
      await ref.read(draftProvider.notifier).replaceFlattened(page.id, flattened);
      if (mounted) showSnack(context, l10n.stampApplied);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _split(DraftPage page) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.bookSplitTitle,
      body: l10n.bookSplitBody,
      confirmLabel: l10n.split,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(draftProvider.notifier).splitPage(page.id);
      if (mounted) showSnack(context, l10n.pageSplitDone);
    } catch (e) {
      if (mounted) showError(context, e);
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
    final notifier = ref.read(draftProvider.notifier);

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
          if (_adjusting)
            _AdjustPanel(
              key: ValueKey('adjust-${page.id}'),
              page: page,
              onChanged: (a) => notifier.setAdjustments(page.id, a),
            )
          else ...[
            _FilterStrip(page: page, onSelected: (f) => notifier.setFilter(page.id, f)),
            if (pages.length > 1)
              TextButton.icon(
                onPressed: () {
                  notifier.applyFilterToAll(page.filter);
                  showSnack(context, l10n.appliedToAll);
                },
                icon: const Icon(Icons.done_all),
                label: Text(l10n.applyToAllPages),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: theme.colorScheme.surfaceContainer,
          child: Row(
            children: [
              Expanded(child: _ToolButton(icon: Icons.crop, label: l10n.crop, onPressed: _busy ? null : () => _crop(page))),
              Expanded(
                child: _ToolButton(
                  icon: Icons.rotate_right,
                  label: l10n.rotate,
                  onPressed: _busy ? null : () => notifier.rotate(page.id),
                ),
              ),
              Expanded(
                child: _ToolButton(
                  icon: Icons.tune,
                  label: l10n.adjust,
                  selected: _adjusting,
                  onPressed: _busy ? null : () => setState(() => _adjusting = !_adjusting),
                ),
              ),
              Expanded(
                child: _ToolButton(
                  icon: Icons.draw_outlined,
                  label: l10n.signTool,
                  onPressed: _busy ? null : () => _sign(page),
                ),
              ),
              Expanded(
                child: _ToolButton(
                  icon: Icons.vertical_split_outlined,
                  label: l10n.bookSplit,
                  onPressed: _busy ? null : () => _split(page),
                ),
              ),
              Expanded(
                child: _ToolButton(
                  icon: Icons.delete_outline,
                  label: l10n.delete,
                  onPressed: _busy ? null : () => _delete(page, pages.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliders for filter strength, brightness and contrast. The preview is
/// recomputed when a slider is released, not on every pixel of movement.
class _AdjustPanel extends StatefulWidget {
  const _AdjustPanel({super.key, required this.page, required this.onChanged});

  final DraftPage page;
  final ValueChanged<PageAdjustments> onChanged;

  @override
  State<_AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<_AdjustPanel> {
  late PageAdjustments _value = widget.page.adjustments;

  @override
  void didUpdateWidget(_AdjustPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.adjustments != widget.page.adjustments) _value = widget.page.adjustments;
  }

  void _commit() => widget.onChanged(_value);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasFilter = widget.page.filter != PageFilter.original;
    Widget slider(String label, double value, double min, double max, ValueChanged<double> onChanged) => Row(
          children: [
            SizedBox(width: 104, child: Text(label, style: theme.textTheme.bodyMedium, maxLines: 2)),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                label: label,
                onChanged: (v) => setState(() => onChanged(v)),
                onChangeEnd: (_) => _commit(),
              ),
            ),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasFilter)
            slider(l10n.filterStrength, _value.strength, 0, 1, (v) => _value = _value.copyWith(strength: v)),
          slider(l10n.brightness, _value.brightness, -1, 1, (v) => _value = _value.copyWith(brightness: v)),
          slider(l10n.contrast, _value.contrast, -1, 1, (v) => _value = _value.copyWith(contrast: v)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _value.isNeutral
                  ? null
                  : () {
                      setState(() => _value = PageAdjustments.none);
                      _commit();
                    },
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.resetAdjustments),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter choices, each shown as a small preview of this page with the
/// filter applied.
class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.page, required this.onSelected});

  final DraftPage page;
  final ValueChanged<PageFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in PageFilter.values)
            Semantics(
              button: true,
              selected: page.filter == f,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(f),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Container(
                          height: 92,
                          // The border is drawn over the picture so the
                          // picture does not resize when selected.
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: page.filter == f
                                ? Border.all(color: scheme.primary, width: 3)
                                : Border.all(color: scheme.outlineVariant),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: scheme.surfaceContainerHighest,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox.expand(
                            // Thumbnails show the plain filter so they stay
                            // comparable while the sliders are tweaked.
                            child: PagePreview(
                              page: page.copyWith(filter: f, adjustments: PageAdjustments.none),
                              cacheWidth: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.filterLabel(f),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: page.filter == f ? scheme.primary : scheme.onSurfaceVariant,
                            fontWeight: page.filter == f ? FontWeight.w700 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onPressed, this.selected = false});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            // Without this the bar grows to the full screen height and hides
            // the page.
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
