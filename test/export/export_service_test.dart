import 'dart:io';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/features/export/data/export_service.dart';
import 'package:banglascanner/features/library/data/document_repository.dart';
import 'package:banglascanner/features/scan/data/draft_document.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';

void main() {
  late Directory root;
  late AppDatabase db;
  late AppPaths paths;
  late DocumentRepository repo;
  late ExportService service;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('bs_test');
    paths = AppPaths(Directory(p.join(root.path, 'docs'))..createSync(), Directory(p.join(root.path, 'tmp'))..createSync());
    db = AppDatabase(NativeDatabase.memory());
    repo = DocumentRepository(db, paths);
    service = ExportService(repo, paths);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  Future<DraftDocument> draftWith(int pages, {String? existingId}) async {
    final dir = Directory(p.join(root.path, 'work'))..createSync(recursive: true);
    final list = <DraftPage>[];
    for (var i = 0; i < pages; i++) {
      final f = File(p.join(dir.path, 'p$i.jpg'))..writeAsBytesSync(fakeDocumentJpeg());
      list.add(DraftPage(id: 'p$i', imagePath: f.path, filter: PageFilter.values[i % 4]));
    }
    return DraftDocument(workDirPath: dir.path, pages: list, existingDocumentId: existingId);
  }

  test('saves a PDF document with metadata, pages and thumbnail', () async {
    final progress = <int>[];
    final doc = await service.save(
      draft: await draftWith(3),
      name: 'Scan 06-10-2026',
      format: SaveFormat.pdf,
      quality: ExportQuality.medium,
      onProgress: (done, _) => progress.add(done),
    );

    expect(progress, [0, 1, 2, 3]);
    expect(doc.pageCount, 3);
    expect(doc.format, SaveFormat.pdf);
    expect(p.isRelative(doc.dirPath), isTrue);
    expect(await repo.pdfOf(doc).exists(), isTrue);
    expect(doc.sizeBytes, await repo.pdfOf(doc).length());
    expect(await repo.thumbnailOf(doc).exists(), isTrue);
    expect((await repo.pagesOf(doc)).length, 3);
    expect(await repo.isIntact(doc), isTrue);
  });

  test('JPEG documents report the total size of their pages', () async {
    final doc = await service.save(
      draft: await draftWith(2),
      name: 'Photos',
      format: SaveFormat.jpeg,
      quality: ExportQuality.low,
    );
    final pages = await repo.pagesOf(doc);
    final total = pages.fold<int>(0, (s, f) => s + f.lengthSync());
    expect(doc.sizeBytes, total);
    expect(await repo.pdfOf(doc).exists(), isFalse);
  });

  test('saving an edited document replaces it and keeps its creation date', () async {
    final first = await service.save(draft: await draftWith(3), name: 'A', format: SaveFormat.pdf, quality: ExportQuality.low);
    final second = await service.save(
      draft: await draftWith(1, existingId: first.id),
      name: 'B',
      format: SaveFormat.jpeg,
      quality: ExportQuality.low,
    );
    expect(second.id, first.id);
    expect(second.createdAt, first.createdAt);
    expect(second.pageCount, 1);
    expect((await repo.pagesOf(second)).length, 1);
    expect(await db.watchDocuments().first, hasLength(1));
  });

  test('a corrupt page fails cleanly without leaving files behind', () async {
    final draft = await draftWith(1);
    File(draft.pages.first.imagePath).writeAsBytesSync([0, 1, 2, 3]);
    await expectLater(
      service.save(draft: draft, name: 'Bad', format: SaveFormat.pdf, quality: ExportQuality.low),
      throwsA(anything),
    );
    expect(await db.watchDocuments().first, isEmpty);
    final leftovers = paths.libraryDir.existsSync() ? paths.libraryDir.listSync() : const [];
    expect(leftovers, isEmpty);
  });

  test('search, sort, rename and delete', () async {
    await service.save(draft: await draftWith(1), name: 'Bank statement', format: SaveFormat.pdf, quality: ExportQuality.low);
    await service.save(draft: await draftWith(1), name: 'আইডি কার্ড', format: SaveFormat.pdf, quality: ExportQuality.low);
    final c = await service.save(draft: await draftWith(1), name: 'Certificate', format: SaveFormat.jpeg, quality: ExportQuality.low);

    expect((await repo.watchAll(search: 'bank').first).map((d) => d.name), ['Bank statement']);
    expect((await repo.watchAll(search: 'কার্ড').first).map((d) => d.name), ['আইডি কার্ড']);
    expect((await repo.watchAll(search: '%').first), isEmpty);
    expect((await repo.watchAll(sort: DocumentSort.nameAz).first).first.name, 'Bank statement');
    expect((await repo.watchAll(sort: DocumentSort.newest).first).first.id, c.id);

    await repo.rename(c.id, 'Award');
    expect((await repo.get(c.id))!.name, 'Award');

    await repo.delete((await repo.get(c.id))!);
    expect(await repo.get(c.id), isNull);
    expect(repo.dirOf(c).existsSync(), isFalse);
  });
}
