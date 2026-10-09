import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/models/enums.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/storage_providers.dart';
import '../../export/data/image_processing.dart';
import '../data/draft_document.dart';

const _uuid = Uuid();

/// Holds the document being scanned/edited (null when there is none).
final draftProvider = NotifierProvider<DraftController, DraftDocument?>(DraftController.new);

/// Top-level on purpose: a closure created inside the notifier would carry
/// it along, and that cannot be sent to another isolate.
Future<(Uint8List, Uint8List)> _splitInBackground(Uint8List bytes, int quarterTurns) =>
    Isolate.run(() => ImageProcessing.splitSpread(bytes, quarterTurns: quarterTurns));

class DraftController extends Notifier<DraftDocument?> {
  /// Filter that fresh photos (scanner or gallery) start with, so a scan
  /// looks clean without any editing. Pages of a saved document keep
  /// [PageFilter.original]: their filter is already baked in.
  static const newPageFilter = PageFilter.autoColor;

  @override
  DraftDocument? build() => null;

  /// Starts a new draft from freshly scanned or picked images.
  Future<void> startNew(List<String> imagePaths) async {
    await discard();
    final paths = await ref.read(appPathsProvider.future);
    final dir = Directory(p.join(paths.workDir.path, _uuid.v4()));
    await dir.create(recursive: true);
    state = DraftDocument(workDirPath: dir.path, pages: await _copyIn(dir, imagePaths, newPageFilter));
  }

  /// Starts a draft from a library document so it can be edited.
  Future<void> startFromDocument(DocumentRow doc, List<String> pageImagePaths) async {
    await discard();
    final paths = await ref.read(appPathsProvider.future);
    final dir = Directory(p.join(paths.workDir.path, _uuid.v4()));
    await dir.create(recursive: true);
    state = DraftDocument(
      workDirPath: dir.path,
      pages: await _copyIn(dir, pageImagePaths, PageFilter.original),
      existingDocumentId: doc.id,
      existingName: doc.name,
      existingFormat: doc.format,
      existingFolderId: doc.folderId,
      existingIsFavorite: doc.isFavorite,
      existingIsProtected: doc.isProtected,
    );
  }

  /// Starts a new draft from the pages of several library documents, in the
  /// given order, so they can be reordered and saved as one document.
  /// The source documents are left untouched.
  Future<void> startMerged(List<String> pageImagePaths, {String? suggestedName}) async {
    await discard();
    final paths = await ref.read(appPathsProvider.future);
    final dir = Directory(p.join(paths.workDir.path, _uuid.v4()));
    await dir.create(recursive: true);
    state = DraftDocument(
      workDirPath: dir.path,
      pages: await _copyIn(dir, pageImagePaths, PageFilter.original),
      suggestedName: suggestedName,
    );
  }

  /// Appends pages (from the scanner or gallery) to the current draft.
  Future<void> addPages(List<String> imagePaths) async {
    final draft = state;
    if (draft == null) return startNew(imagePaths);
    final added = await _copyIn(Directory(draft.workDirPath), imagePaths, newPageFilter);
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

  void setAdjustments(String pageId, PageAdjustments adjustments) =>
      _updatePage(pageId, (pg) => pg.copyWith(adjustments: adjustments));

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

  /// Book mode: cuts the page into two pages (left/right, or top/bottom for
  /// a tall photo) that take its place. Filter and adjustments are kept.
  Future<void> splitPage(String pageId) async {
    final draft = state;
    if (draft == null) return;
    final index = draft.pages.indexWhere((pg) => pg.id == pageId);
    if (index < 0) return;
    final page = draft.pages[index];
    final (first, second) = await _splitInBackground(await File(page.imagePath).readAsBytes(), page.quarterTurns);
    final halves = <DraftPage>[];
    for (final bytes in [first, second]) {
      final id = _uuid.v4();
      final target = p.join(draft.workDirPath, '$id.jpg');
      await File(target).writeAsBytes(bytes, flush: true);
      halves.add(DraftPage(id: id, imagePath: target, filter: page.filter, adjustments: page.adjustments));
    }
    // The draft may have changed while the image was being cut.
    final current = state;
    if (current == null) return;
    final pages = [...current.pages];
    final at = pages.indexWhere((pg) => pg.id == pageId);
    if (at < 0) return;
    pages.replaceRange(at, at + 1, halves);
    state = current.copyWith(pages: pages);
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
  Future<List<DraftPage>> _copyIn(Directory dir, List<String> sources, PageFilter filter) async {
    final pages = <DraftPage>[];
    for (final source in sources) {
      final id = _uuid.v4();
      final ext = p.extension(source).isEmpty ? '.jpg' : p.extension(source).toLowerCase();
      final target = p.join(dir.path, '$id$ext');
      await File(source).copy(target);
      pages.add(DraftPage(id: id, imagePath: target, filter: filter));
    }
    return pages;
  }
}
