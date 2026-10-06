import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/library_providers.dart';
import 'document_tile.dart';

/// All saved documents with search and sorting.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late final _search = TextEditingController(text: ref.read(librarySearchProvider));

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final docs = ref.watch(libraryDocumentsProvider);
    final sort = ref.watch(librarySortProvider);
    final searching = ref.watch(librarySearchProvider).trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          PopupMenuButton<DocumentSort>(
            tooltip: l10n.sortBy,
            icon: const Icon(Icons.sort),
            initialValue: sort,
            onSelected: ref.read(librarySortProvider.notifier).set,
            itemBuilder: (context) => [
              for (final s in DocumentSort.values) CheckedPopupMenuItem(value: s, checked: s == sort, child: Text(_sortLabel(s))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
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
                  itemBuilder: (context, i) => DocumentTile(key: ValueKey(list[i].id), doc: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
