import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/models/enums.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/draft_document.dart';

const _uuid = Uuid();

/// Holds the document being scanned/edited (null when there is none).
final draftProvider = NotifierProvider<DraftController, DraftDocument?>(DraftController.new);

class DraftController extends Notifier<DraftDocument?> {
  @override
  DraftDocument? build() => null;

  /// Starts a new draft from freshly scanned or picked images.
  Future<void> startNew(List<String> imagePaths) async {
    await discard();
    final paths = await ref.read(appPathsProvider.future);
    final dir = Directory(p.join(paths.workDir.path, _uuid.v4()));
    await dir.create(recursive: true);
    state = DraftDocument(workDirPath: dir.path, pages: await _copyIn(dir, imagePaths));
  }

  /// Starts a draft from a library document so it can be edited.
  Future<void> startFromDocument(DocumentRow doc, List<String> pageImagePaths) async {
    await discard();
    final paths = await ref.read(appPathsProvider.future);
    final dir = Directory(p.join(paths.workDir.path, _uuid.v4()));
    await dir.create(recursive: true);
    state = DraftDocument(
      workDirPath: dir.path,
      pages: await _copyIn(dir, pageImagePaths),
      existingDocumentId: doc.id,
      existingName: doc.name,
      existingFormat: doc.format,
    );
  }

  /// Appends pages (from the scanner or gallery) to the current draft.
  Future<void> addPages(List<String> imagePaths) async {
    final draft = state;
    if (draft == null) return startNew(imagePaths);
    final added = await _copyIn(Directory(draft.workDirPath), imagePaths);
    state = draft.copyWith(pages: [...draft.pages, ...added]);
  }

  void reorder(int oldIndex, int newIndex) {
    final draft = state;
    if (draft == null) return;
    final pages = [...draft.pages];
    // newIndex is the final position (ReorderableListView.onReorderItem
    // already accounts for the removed item).
    pages.insert(newIndex, pages.removeAt(oldIndex));
    state = draft.copyWith(pages: pages);
  }

  void rotate(String pageId) => _updatePage(pageId, (pg) => pg.copyWith(quarterTurns: (pg.quarterTurns + 1) % 4));

  void setFilter(String pageId, PageFilter filter) => _updatePage(pageId, (pg) => pg.copyWith(filter: filter));

  void applyFilterToAll(PageFilter filter) {
    final draft = state;
    if (draft == null) return;
    state = draft.copyWith(pages: [for (final pg in draft.pages) pg.copyWith(filter: filter)]);
  }

  /// Replaces a page's image (e.g. with the cropped result). Rotation is
  /// reset because the cropper already outputs the image the user saw.
  Future<void> replaceImage(String pageId, String newImagePath) async {
    final draft = state;
    if (draft == null) return;
    final target = p.join(draft.workDirPath, '${_uuid.v4()}${p.extension(newImagePath)}');
    await File(newImagePath).copy(target);
    _updatePage(pageId, (pg) => pg.copyWith(imagePath: target, quarterTurns: 0, revision: pg.revision + 1));
  }

  void deletePage(String pageId) {
    final draft = state;
    if (draft == null) return;
    state = draft.copyWith(pages: draft.pages.where((pg) => pg.id != pageId).toList());
  }

  /// Drops the draft and its working files.
  Future<void> discard() async {
    final draft = state;
    state = null;
    if (draft != null) {
      try {
        await Directory(draft.workDirPath).delete(recursive: true);
      } catch (_) {
        // Temp files; the OS cleans them eventually.
      }
    }
  }

  void _updatePage(String pageId, DraftPage Function(DraftPage) update) {
    final draft = state;
    if (draft == null) return;
    state = draft.copyWith(pages: [for (final pg in draft.pages) pg.id == pageId ? update(pg) : pg]);
  }

  /// Copies source images into the draft folder so later edits never touch
  /// the user's originals or plugin caches that may be cleared.
  Future<List<DraftPage>> _copyIn(Directory dir, List<String> sources) async {
    final pages = <DraftPage>[];
    for (final source in sources) {
      final id = _uuid.v4();
      final ext = p.extension(source).isEmpty ? '.jpg' : p.extension(source).toLowerCase();
      final target = p.join(dir.path, '$id$ext');
      await File(source).copy(target);
      pages.add(DraftPage(id: id, imagePath: target));
    }
    return pages;
  }
}
