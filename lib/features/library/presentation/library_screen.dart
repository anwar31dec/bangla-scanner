import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/progress_overlay.dart';
import '../application/library_providers.dart';
import 'document_actions.dart';
import 'document_tile.dart';

/// All saved documents with search and sorting. Long-press a document (or
/// tap the merge icon) to enter selection mode and merge several documents
/// into one new PDF / image set.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final _search = TextEditingController(text: ref.read(librarySearchProvider));

  bool _selecting = false;

  /// Selected document ids in the order they were tapped: this is the page
  /// order of the merged document.
  final List<String> _selected = [];
  bool _merging = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _sortLabel(DocumentSort s) {
    final l10n = context.l10n;
    return switch (s) {
      DocumentSort.newest => l10n.sortNewest,
      DocumentSort.oldest => l10n.sortOldest,
      DocumentSort.nameAz => l10n.sortNameAz,
      DocumentSort.nameZa => l10n.sortNameZa,
    };
  }

  void _startSelecting([String? firstId]) {
    setState(() {
      _selecting = true;
      _selected.clear();
      if (firstId != null) _selected.add(firstId);
    });
  }

  void _stopSelecting() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _merge(List<DocumentRow> visible) async {
    final l10n = context.l10n;
    if (_selected.length < 2) {
      showSnack(context, l10n.mergeNeedTwo);
      return;
    }
    // Resolve ids → rows in selection order (ignore anything that was
    // deleted or filtered away meanwhile).
    final byId = {for (final d in visible) d.id: d};
    final docs = [for (final id in _selected) if (byId[id] != null) byId[id]!];
    if (docs.length < 2) {
      showSnack(context, l10n.mergeNeedTwo);
      return;
    }
    setState(() => _merging = true);
    try {
      final opened = await DocumentActions.merge(context, ref, docs);
      if (opened && mounted) _stopSelecting();
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final docs = ref.watch(libraryDocumentsProvider);
    final sort = ref.watch(librarySortProvider);
    final searching = ref.watch(librarySearchProvider).trim().isNotEmpty;
    final theme = Theme.of(context);

    final visible = docs.value ?? const <DocumentRow>[];

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selecting && !_merging) _stopSelecting();
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: _selecting
                ? AppBar(
                    leading: IconButton(icon: const Icon(Icons.close), tooltip: l10n.close, onPressed: _merging ? null : _stopSelecting),
                    title: Text(l10n.mergeSelected(_selected.length)),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilledButton.icon(
                          onPressed: _merging || _selected.length < 2 ? null : () => _merge(visible),
                          icon: const Icon(Icons.merge_type),
                          label: Text(l10n.merge),
                        ),
                      ),
                    ],
                  )
                : AppBar(
                    title: Text(l10n.libraryTitle),
                    actions: [
                      if (visible.length >= 2)
                        IconButton(
                          tooltip: l10n.mergeTooltip,
                          icon: const Icon(Icons.merge_type),
                          onPressed: () => _startSelecting(),
                        ),
                      PopupMenuButton<DocumentSort>(
                        tooltip: l10n.sortBy,
                        icon: const Icon(Icons.sort),
                        initialValue: sort,
                        onSelected: ref.read(librarySortProvider.notifier).set,
                        itemBuilder: (context) => [
                          for (final s in DocumentSort.values)
                            CheckedPopupMenuItem(value: s, checked: s == sort, child: Text(_sortLabel(s))),
                        ],
                      ),
                    ],
                  ),
            body: Column(
              children: [
                if (_selecting)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(l10n.mergeHint, style: theme.textTheme.bodySmall),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searching
                            ? IconButton(
                                tooltip: l10n.close,
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  ref.read(librarySearchProvider.notifier).set('');
                                },
                              )
                            : null,
                      ),
                      onChanged: ref.read(librarySearchProvider.notifier).set,
                    ),
                  ),
                Expanded(
                  child: docs.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: EmptyState(icon: Icons.error_outline, title: l10n.errorGeneric)),
                    data: (list) {
                      if (list.isEmpty) {
                        return Center(
                          child: searching
                              ? EmptyState(icon: Icons.search_off, title: l10n.librarySearchEmpty)
                              : EmptyState(icon: Icons.folder_open_outlined, title: l10n.libraryEmpty),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final doc = list[i];
                          final order = _selected.indexOf(doc.id);
                          return DocumentTile(
                            key: ValueKey(doc.id),
                            doc: doc,
                            selecting: _selecting,
                            selectionOrder: order < 0 ? null : order + 1,
                            onToggle: _merging ? null : () => _toggle(doc.id),
                            onLongPress: () => _startSelecting(doc.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_merging) ProgressOverlay(message: l10n.mergePreparing),
        ],
      ),
    );
  }
}
