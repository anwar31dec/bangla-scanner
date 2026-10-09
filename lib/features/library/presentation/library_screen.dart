import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/progress_overlay.dart';
import '../application/library_providers.dart';
import '../data/document_repository.dart';
import 'document_actions.dart';
import 'document_tile.dart';

/// All saved documents with search, sorting, folders and favourites.
/// Long-press a document (or tap Select) to enter selection mode: share,
/// move, star, delete or merge several documents at once.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final _search = TextEditingController(text: ref.read(librarySearchProvider));

  bool _selecting = false;

  /// Selected document ids in the order they were tapped: this is the page
  /// order of a merged document.
  final List<String> _selected = [];
  bool _busy = false;

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

  void _selectAll(List<DocumentRow> visible) {
    setState(() {
      for (final d in visible) {
        if (!_selected.contains(d.id)) _selected.add(d.id);
      }
    });
  }

  /// Selected rows in selection order (ignoring anything deleted or
  /// filtered away meanwhile).
  List<DocumentRow> _selectedDocs(List<DocumentRow> visible) {
    final byId = {for (final d in visible) d.id: d};
    return [for (final id in _selected) if (byId[id] != null) byId[id]!];
  }

  /// Runs [action] on the selected documents and leaves selection mode when
  /// it reports success. [progress] shows the busy overlay (merging copies
  /// files; the other actions only confirm or open a sheet).
  Future<void> _run(
    Future<bool> Function(List<DocumentRow> docs) action,
    List<DocumentRow> visible, {
    int min = 1,
    bool progress = false,
  }) async {
    final docs = _selectedDocs(visible);
    if (docs.length < min || _busy) return;
    setState(() => _busy = progress);
    try {
      final done = await action(docs);
      if (done && mounted) _stopSelecting();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _merge(List<DocumentRow> visible) async {
    if (_selectedDocs(visible).length < 2) {
      showSnack(context, context.l10n.mergeNeedTwo);
      return;
    }
    await _run((docs) => DocumentActions.merge(context, ref, docs), visible, min: 2, progress: true);
  }

  Future<void> _folderMenu(FolderRow folder) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.folder_outlined), title: Text(folder.name, style: Theme.of(context).textTheme.titleMedium)),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(l10n.renameFolder),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.deleteFolder),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'rename') {
      await DocumentActions.renameFolder(context, ref, folder);
    } else if (await DocumentActions.deleteFolder(context, ref, folder)) {
      if (ref.read(libraryFilterProvider) == LibraryFilter.folder(folder.id)) {
        ref.read(libraryFilterProvider.notifier).set(LibraryFilter.all);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final docs = ref.watch(libraryDocumentsProvider);
    final sort = ref.watch(librarySortProvider);
    final filter = ref.watch(libraryFilterProvider);
    final searchTerm = ref.watch(librarySearchProvider).trim();
    final searching = searchTerm.isNotEmpty;
    final textMatches = searching ? ref.watch(libraryTextMatchesProvider).value ?? const <String, String>{} : const <String, String>{};
    final theme = Theme.of(context);

    final visible = docs.value ?? const <DocumentRow>[];
    final selectedDocs = _selectedDocs(visible);
    final allFavorite = selectedDocs.isNotEmpty && selectedDocs.every((d) => d.isFavorite);

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selecting && !_busy) _stopSelecting();
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: _selecting
                ? AppBar(
                    leading: IconButton(icon: const Icon(Icons.close), tooltip: l10n.close, onPressed: _busy ? null : _stopSelecting),
                    title: Text(l10n.selectedCount(_selected.length)),
                    actions: [
                      IconButton(
                        tooltip: l10n.selectAll,
                        icon: const Icon(Icons.select_all),
                        onPressed: _busy ? null : () => _selectAll(visible),
                      ),
                    ],
                  )
                : AppBar(
                    title: Text(l10n.libraryTitle),
                    actions: [
                      if (visible.isNotEmpty)
                        IconButton(
                          tooltip: l10n.select,
                          icon: const Icon(Icons.checklist),
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
                    child: Text(l10n.selectionHint, style: theme.textTheme.bodySmall),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
                  _FilterChips(onFolderLongPress: _folderMenu),
                ],
                Expanded(
                  child: docs.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: EmptyState(icon: Icons.error_outline, title: l10n.errorGeneric)),
                    data: (list) {
                      if (list.isEmpty) {
                        return Center(
                          child: searching
                              ? EmptyState(icon: Icons.search_off, title: l10n.librarySearchEmpty)
                              : switch (filter) {
                                  FolderFilter() => EmptyState(icon: Icons.folder_open_outlined, title: l10n.folderEmpty),
                                  _ when filter == LibraryFilter.favorites =>
                                    EmptyState(icon: Icons.star_outline_rounded, title: l10n.favoritesEmpty),
                                  _ => EmptyState(icon: Icons.folder_open_outlined, title: l10n.libraryEmpty),
                                },
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final doc = list[i];
                          final order = _selected.indexOf(doc.id);
                          // Say where a hit came from when the name alone does not explain it.
                          final matchedText = textMatches[doc.id];
                          final snippet = matchedText != null && !doc.name.toLowerCase().contains(searchTerm.toLowerCase())
                              ? DocumentRepository.textSnippet(matchedText, searchTerm)
                              : null;
                          return DocumentTile(
                            key: ValueKey(doc.id),
                            doc: doc,
                            textMatch: snippet,
                            selecting: _selecting,
                            selectionOrder: order < 0 ? null : order + 1,
                            onToggle: _busy ? null : () => _toggle(doc.id),
                            onLongPress: () => _startSelecting(doc.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _selecting
                ? _SelectionBar(
                    enabled: !_busy && selectedDocs.isNotEmpty,
                    mergeEnabled: !_busy && selectedDocs.length >= 2,
                    allFavorite: allFavorite,
                    onShare: () => _run((docs) async {
                      await DocumentActions.shareMany(context, ref, docs);
                      return false;
                    }, visible),
                    onMove: () => _run((docs) => DocumentActions.moveToFolder(context, ref, docs), visible),
                    onFavorite: () => _run((docs) async {
                      await DocumentActions.setFavorite(context, ref, docs, !allFavorite);
                      return true;
                    }, visible),
                    onDelete: () => _run((docs) => DocumentActions.deleteMany(context, ref, docs), visible),
                    onMerge: () => _merge(visible),
                  )
                : null,
          ),
          if (_busy) ProgressOverlay(message: l10n.mergePreparing),
        ],
      ),
    );
  }
}

/// All / Favourites / folder chips, plus "New folder".
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.onFolderLongPress});

  final ValueChanged<FolderRow> onFolderLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(libraryFilterProvider);
    final folders = ref.watch(foldersProvider).value ?? const <FolderRow>[];
    final counts = ref.watch(folderCountsProvider).value ?? const <String, int>{};
    final set = ref.read(libraryFilterProvider.notifier).set;

    // The folder shown may have been deleted elsewhere.
    if (filter is FolderFilter && ref.watch(foldersProvider).hasValue && !folders.any((f) => f.id == filter.folderId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => set(LibraryFilter.all));
    }

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(l10n.filterAll),
              selected: filter == LibraryFilter.all,
              onSelected: (_) => set(LibraryFilter.all),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: const Icon(Icons.star_rounded, size: 18),
              label: Text(l10n.favorites),
              selected: filter == LibraryFilter.favorites,
              onSelected: (_) => set(LibraryFilter.favorites),
            ),
          ),
          for (final f in folders)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onLongPress: () => onFolderLongPress(f),
                child: ChoiceChip(
                  avatar: const Icon(Icons.folder_outlined, size: 18),
                  label: Text(counts[f.id] == null ? f.name : '${f.name} (${counts[f.id]})'),
                  selected: filter == LibraryFilter.folder(f.id),
                  onSelected: (_) => set(LibraryFilter.folder(f.id)),
                ),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: Text(l10n.newFolder),
            onPressed: () async {
              final folder = await DocumentActions.createFolder(context, ref);
              if (folder != null) set(LibraryFilter.folder(folder.id));
            },
          ),
        ],
      ),
    );
  }
}

/// Actions for the selected documents.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.enabled,
    required this.mergeEnabled,
    required this.allFavorite,
    required this.onShare,
    required this.onMove,
    required this.onFavorite,
    required this.onDelete,
    required this.onMerge,
  });

  final bool enabled;
  final bool mergeEnabled;
  final bool allFavorite;
  final VoidCallback onShare;
  final VoidCallback onMove;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget action(IconData icon, String label, VoidCallback onTap, {bool on = true}) => Expanded(
          child: InkWell(
            onTap: on ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: on ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.38)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: on ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.38),
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
    return SafeArea(
      child: Material(
        color: scheme.surfaceContainer,
        child: Row(
          children: [
            action(Icons.share_outlined, l10n.share, onShare, on: enabled),
            action(Icons.drive_file_move_outline, l10n.moveToFolder, onMove, on: enabled),
            action(allFavorite ? Icons.star_outline_rounded : Icons.star_rounded, l10n.favorites, onFavorite, on: enabled),
            action(Icons.delete_outline, l10n.delete, onDelete, on: enabled),
            action(Icons.merge_type, l10n.merge, onMerge, on: mergeEnabled),
          ],
        ),
      ),
    );
  }
}
