import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/library_providers.dart';
import 'document_actions.dart';

/// Opens a saved document: swipe through pages, pinch or double-tap to
/// zoom, jump with the thumbnail strip; share, save to phone, extract text,
/// edit, reorder pages, star, move, rename or delete.
class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

enum _MenuAction { rename, edit, pages, move, delete }

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  final _pageController = PageController();
  int _current = 0;

  /// While a page is zoomed in, dragging pans it instead of flipping pages.
  bool _zoomed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onMenu(_MenuAction action, DocumentRow doc) async {
    switch (action) {
      case _MenuAction.rename:
        await DocumentActions.rename(context, ref, doc);
      case _MenuAction.edit:
        await DocumentActions.edit(context, ref, doc);
      case _MenuAction.pages:
        DocumentActions.reorderPages(context, doc);
      case _MenuAction.move:
        await DocumentActions.moveToFolder(context, ref, [doc]);
      case _MenuAction.delete:
        if (await DocumentActions.delete(context, ref, doc) && mounted) context.pop();
    }
  }

  void _goTo(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final docAsync = ref.watch(documentProvider(widget.documentId));
    final doc = docAsync.value;

    if (docAsync.isLoading && doc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: EmptyState(icon: Icons.error_outline, title: l10n.documentMissing)),
      );
    }

    final pagesAsync = ref.watch(documentPagesProvider(doc.id));
    final pages = pagesAsync.value ?? const <File>[];
    final locale = context.localeTag;
    final theme = Theme.of(context);
    final current = _current.clamp(0, pages.isEmpty ? 0 : pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: doc.isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
            icon: Icon(doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
            color: doc.isFavorite ? theme.colorScheme.tertiary : null,
            onPressed: () => DocumentActions.toggleFavorite(context, ref, doc),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (a) => _onMenu(a, doc),
            itemBuilder: (context) => [
              PopupMenuItem(value: _MenuAction.rename, child: ListTile(leading: const Icon(Icons.drive_file_rename_outline), title: Text(l10n.rename))),
              PopupMenuItem(value: _MenuAction.edit, child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l10n.edit))),
              PopupMenuItem(value: _MenuAction.pages, child: ListTile(leading: const Icon(Icons.swap_vert), title: Text(l10n.reorderPages))),
              PopupMenuItem(value: _MenuAction.move, child: ListTile(leading: const Icon(Icons.drive_file_move_outline), title: Text(l10n.moveToFolder))),
              PopupMenuItem(value: _MenuAction.delete, child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(l10n.delete))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  [
                    l10n.formatLabel(doc.format),
                    l10n.editorPages(doc.pageCount),
                    Formatters.fileSize(doc.sizeBytes, locale),
                    Formatters.dateTime(doc.createdAt, locale),
                  ].join('  ·  '),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                if (doc.isProtected)
                  Tooltip(
                    message: l10n.protectedBadge,
                    child: Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.primary),
                  ),
                if (doc.hasText)
                  Tooltip(
                    message: l10n.searchableBadge,
                    child: Icon(Icons.text_snippet_outlined, size: 16, color: theme.colorScheme.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: pagesAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pages.isEmpty
                    ? Center(child: EmptyState(icon: Icons.broken_image_outlined, title: l10n.documentMissing))
                    : PageView.builder(
                        controller: _pageController,
                        physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                        itemCount: pages.length,
                        onPageChanged: (i) => setState(() {
                          _current = i;
                          _zoomed = false;
                        }),
                        itemBuilder: (context, i) => ZoomablePage(
                          key: ValueKey('${pages[i].path}-${doc.updatedAt.millisecondsSinceEpoch}'),
                          file: pages[i],
                          active: i == current,
                          onZoomChanged: (z) {
                            if (i == current && z != _zoomed) setState(() => _zoomed = z);
                          },
                          errorText: l10n.errorCorruptFile,
                        ),
                      ),
          ),
          if (pages.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l10n.pageEditTitle(current + 1, pages.length), style: theme.textTheme.bodyMedium),
            ),
            _ThumbnailStrip(pages: pages, current: current, revision: doc.updatedAt.millisecondsSinceEpoch, onTap: _goTo),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: pages.isEmpty ? null : () => context.push(Routes.ocrPath(doc.id)),
                icon: const Icon(Icons.text_snippet_outlined),
                label: Text(l10n.extractText),
              ),
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
                child: Builder(
                  builder: (context) => FilledButton.icon(
                    onPressed: () => DocumentActions.share(context, ref, doc),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(l10n.share),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => DocumentActions.saveToDevice(context, ref, doc),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.saveToDevice, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One page of the viewer: pinch to zoom, double-tap to zoom in on that
/// spot (and again to zoom out). Reports whether it is zoomed so the
/// surrounding PageView can stop flipping pages while the user pans.
class ZoomablePage extends StatefulWidget {
  const ZoomablePage({
    super.key,
    required this.file,
    required this.active,
    required this.onZoomChanged,
    required this.errorText,
  });

  final File file;

  /// False once the user has swiped to another page: the zoom is reset.
  final bool active;
  final ValueChanged<bool> onZoomChanged;
  final String errorText;

  /// Scale applied by a double tap.
  static const doubleTapScale = 2.5;

  @override
  State<ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<ZoomablePage> with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  Animation<Matrix4>? _tween;
  TapDownDetails? _lastTap;

  @override
  void initState() {
    super.initState();
    _animation.addListener(() {
      final t = _tween;
      if (t != null) _transform.value = t.value;
    });
  }

  @override
  void didUpdateWidget(ZoomablePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active) _reset();
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  bool get _isZoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(begin: _transform.value, end: target).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOut));
    _animation
      ..reset()
      ..forward().whenComplete(() => widget.onZoomChanged(_isZoomed));
  }

  void _reset() {
    _animation.stop();
    _transform.value = Matrix4.identity();
    widget.onZoomChanged(false);
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    final tap = _lastTap?.localPosition;
    if (tap == null) return;
    const s = ZoomablePage.doubleTapScale;
    // Keep the tapped point where it is while scaling around it.
    final target = Matrix4.identity()
      ..translateByDouble(-tap.dx * (s - 1), -tap.dy * (s - 1), 0, 1)
      ..scaleByDouble(s, s, 1, 1);
    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _lastTap = d,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 6,
        onInteractionEnd: (_) => widget.onZoomChanged(_isZoomed),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Image.file(
              widget.file,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) =>
                  Center(child: EmptyState(icon: Icons.broken_image_outlined, title: widget.errorText)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small page thumbnails under the viewer; the current page is outlined.
class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({required this.pages, required this.current, required this.revision, required this.onTap});

  final List<File> pages;
  final int current;
  final int revision;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: pages.length,
        itemBuilder: (context, i) {
          final selected = i == current;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onTap(i),
              child: Container(
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(
                  pages[i],
                  key: ValueKey('${pages[i].path}-$revision'),
                  fit: BoxFit.cover,
                  cacheWidth: 120,
                  errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined, size: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
