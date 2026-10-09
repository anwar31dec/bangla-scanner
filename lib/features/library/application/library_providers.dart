import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_database.dart';
import '../data/document_repository.dart';

/// Search text typed in the library.
final librarySearchProvider = NotifierProvider<_StringNotifier, String>(_StringNotifier.new);

/// Current library sort order.
final librarySortProvider = NotifierProvider<_SortNotifier, DocumentSort>(_SortNotifier.new);

/// All / favourites / one folder.
final libraryFilterProvider = NotifierProvider<_FilterNotifier, LibraryFilter>(_FilterNotifier.new);

class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

class _SortNotifier extends Notifier<DocumentSort> {
  @override
  DocumentSort build() => DocumentSort.newest;
  void set(DocumentSort value) => state = value;
}

class _FilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => LibraryFilter.all;
  void set(LibraryFilter value) => state = value;
}

/// Filtered + sorted documents for the library screen.
final libraryDocumentsProvider = StreamProvider<List<DocumentRow>>((ref) async* {
  final repo = await ref.watch(documentRepositoryProvider.future);
  yield* repo.watchAll(
    search: ref.watch(librarySearchProvider),
    sort: ref.watch(librarySortProvider),
    filter: ref.watch(libraryFilterProvider),
  );
});

/// Every document, regardless of the library's search and filter (backup).
final allDocumentsProvider = StreamProvider<List<DocumentRow>>((ref) async* {
  final repo = await ref.watch(documentRepositoryProvider.future);
  yield* repo.watchAll();
});

/// The few most recent documents shown on the home screen.
final recentDocumentsProvider = StreamProvider<List<DocumentRow>>((ref) async* {
  final repo = await ref.watch(documentRepositoryProvider.future);
  yield* repo.watchAll(limit: 5);
});

/// One document, live (null once deleted).
final documentProvider = StreamProvider.family<DocumentRow?, String>((ref, id) async* {
  final repo = await ref.watch(documentRepositoryProvider.future);
  yield* repo.watch(id);
});

/// Page images of a document (re-read when the document changes).
final documentPagesProvider = FutureProvider.family<List<File>, String>((ref, id) async {
  final repo = await ref.watch(documentRepositoryProvider.future);
  final doc = await ref.watch(documentProvider(id).future);
  if (doc == null) return const [];
  return repo.pagesOf(doc);
});

/// All folders, by name.
final foldersProvider = StreamProvider<List<FolderRow>>((ref) async* {
  final repo = await ref.watch(documentRepositoryProvider.future);
  yield* repo.watchFolders();
});

/// Documents per folder id.
final folderCountsProvider = StreamProvider<Map<String, int>>((ref) async* {
  final repo = await ref.watch(documentRepositoryProvider.future);
  yield* repo.watchFolderCounts();
});
