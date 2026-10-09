import 'dart:io';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/core/storage/storage_providers.dart';
import 'package:banglascanner/features/scan/application/draft_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';

void main() {
  late Directory root;
  late ProviderContainer container;
  late List<String> sources;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('bs_draft');
    final paths = AppPaths(Directory(p.join(root.path, 'docs')), Directory(p.join(root.path, 'tmp')));
    container = ProviderContainer(overrides: [appPathsProvider.overrideWith((ref) async => paths)]);
    sources = [
      for (var i = 0; i < 3; i++) (File(p.join(root.path, 'src$i.jpg'))..writeAsBytesSync(fakeDocumentJpeg(width: 60, height: 80))).path,
    ];
  });

  tearDown(() async {
    container.dispose();
    await root.delete(recursive: true);
  });

  DraftController controller() => container.read(draftProvider.notifier);
  List<String> order() => container.read(draftProvider)!.pages.map((pg) => pg.id).toList();

  test('copies images into a private work folder', () async {
    await controller().startNew(sources);
    final draft = container.read(draftProvider)!;
    expect(draft.pages, hasLength(3));
    for (final pg in draft.pages) {
      expect(pg.imagePath, startsWith(draft.workDirPath));
      expect(File(pg.imagePath).existsSync(), isTrue);
    }
  });

  test('reorder, rotate, filter, delete and add pages', () async {
    await controller().startNew(sources);
    final ids = order();

    controller().reorder(0, 2);
    expect(order(), [ids[1], ids[2], ids[0]]);

    controller().rotate(ids[0]);
    controller().rotate(ids[0]);
    controller().rotate(ids[0]);
    controller().rotate(ids[0]);
    controller().rotate(ids[0]);
    expect(container.read(draftProvider)!.pages.last.quarterTurns, 1);

    controller().setFilter(ids[1], PageFilter.blackWhite);
    expect(container.read(draftProvider)!.pages.first.filter, PageFilter.blackWhite);
    controller().applyFilterToAll(PageFilter.grayscale);
    expect(container.read(draftProvider)!.pages.every((pg) => pg.filter == PageFilter.grayscale), isTrue);

    controller().deletePage(ids[2]);
    expect(order(), [ids[1], ids[0]]);

    await controller().addPages([sources.first]);
    expect(order(), hasLength(3));
  });

  test('fresh photos start with auto color, pages of a saved document stay as they are', () async {
    await controller().startNew(sources);
    await controller().addPages([sources.first]);
    expect(container.read(draftProvider)!.pages.map((pg) => pg.filter), everyElement(PageFilter.autoColor));

    final now = DateTime(2026, 10, 6);
    final doc = DocumentRow(
      id: 'doc',
      name: 'Saved',
      format: SaveFormat.pdf,
      dirPath: root.path,
      pageCount: 2,
      sizeBytes: 1,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
      isProtected: false,
      hasText: false,
    );
    await controller().startFromDocument(doc, sources.take(2).toList());
    expect(container.read(draftProvider)!.pages.map((pg) => pg.filter), everyElement(PageFilter.original));
    // A page photographed now and added to the saved document is fresh.
    await controller().addPages([sources.last]);
    expect(container.read(draftProvider)!.pages.last.filter, PageFilter.autoColor);
  });

  test('replacing an image (crop) resets rotation and bumps revision', () async {
    await controller().startNew(sources);
    final id = order().first;
    controller().rotate(id);
    await controller().replaceImage(id, sources[2]);
    final pg = container.read(draftProvider)!.pages.first;
    expect(pg.quarterTurns, 0);
    expect(pg.revision, 1);
  });

  test('discard removes working files', () async {
    await controller().startNew(sources);
    final dir = container.read(draftProvider)!.workDirPath;
    await controller().discard();
    expect(container.read(draftProvider), isNull);
    expect(Directory(dir).existsSync(), isFalse);
  });

  test('PDF pages can start with the original filter', () async {
    await controller().startNew(sources, filter: PageFilter.original);
    expect(container.read(draftProvider)!.pages.every((pg) => pg.filter == PageFilter.original), isTrue);
    await controller().addPages([sources.first]);
    expect(container.read(draftProvider)!.pages.last.filter, DraftController.newPageFilter);
  });

  test('replaceFlattened writes the new image and clears pending edits', () async {
    await controller().startNew(sources);
    final id = order().first;
    controller().rotate(id);
    controller().setFilter(id, PageFilter.blackWhite);
    final before = container.read(draftProvider)!.pages.first;

    final flattened = fakeDocumentJpeg(width: 80, height: 60);
    await controller().replaceFlattened(id, flattened);

    final after = container.read(draftProvider)!.pages.first;
    expect(after.id, id);
    expect(after.imagePath, isNot(before.imagePath));
    expect(after.imagePath, startsWith(container.read(draftProvider)!.workDirPath));
    expect(File(after.imagePath).readAsBytesSync(), flattened);
    expect(after.quarterTurns, 0);
    expect(after.filter, PageFilter.original);
    expect(after.adjustments.isNeutral, isTrue);
    expect(after.revision, before.revision + 1);
  });
}
