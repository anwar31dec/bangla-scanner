import 'dart:convert';
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
    root = await Directory.systemTemp.createTemp('bs_pages');
    paths = AppPaths(Directory(p.join(root.path, 'docs'))..createSync(), Directory(p.join(root.path, 'tmp'))..createSync());
    db = AppDatabase(NativeDatabase.memory());
    repo = DocumentRepository(db, paths);
    service = ExportService(repo, paths);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  Future<DocumentRow> saved({String? password}) async {
    final dir = Directory(p.join(root.path, 'work'))..createSync(recursive: true);
    final pages = <DraftPage>[];
    for (var i = 0; i < 3; i++) {
      // Distinct sizes so pages can be told apart after the rewrite.
      final f = File(p.join(dir.path, 'p$i.jpg'))..writeAsBytesSync(fakeDocumentJpeg(width: 100 + i * 20, height: 140));
      pages.add(DraftPage(id: 'p$i', imagePath: f.path));
    }
    return service.save(
      draft: DraftDocument(workDirPath: dir.path, pages: pages),
      name: 'Doc',
      format: SaveFormat.pdf,
      quality: ExportQuality.low,
      password: password,
    );
  }

  test('reorders and removes pages without re-encoding them', () async {
    final doc = await saved();
    final before = await repo.pagesOf(doc);
    final bytesBefore = [for (final f in before) f.readAsBytesSync()];

    // New order: third, first; the second page is dropped.
    await repo.rewritePages(doc, [before[2], before[0]]);

    final after = (await repo.get(doc.id))!;
    expect(after.pageCount, 2);
    expect(after.updatedAt.isAfter(doc.updatedAt) || after.updatedAt.isAtSameMomentAs(doc.updatedAt), isTrue);
    final pages = await repo.pagesOf(after);
    expect(pages.map((f) => p.basename(f.path)), ['page_001.jpg', 'page_002.jpg']);
    expect(pages[0].readAsBytesSync(), bytesBefore[2], reason: 'bytes are moved, not re-encoded');
    expect(pages[1].readAsBytesSync(), bytesBefore[0]);
    expect(repo.pdfOf(after).existsSync(), isTrue);
    expect(latin1.decode(repo.pdfOf(after).readAsBytesSync()), contains('/Count 2'));
    expect(after.sizeBytes, repo.pdfOf(after).lengthSync());
    expect(Directory('${repo.dirOf(after).path}.staging').existsSync(), isFalse);
  });

  test('a protected PDF is rebuilt encrypted when the password is given', () async {
    final doc = await saved(password: 'secret');
    expect(doc.isProtected, isTrue);
    expect(latin1.decode(repo.pdfOf(doc).readAsBytesSync()), contains('/Encrypt'));

    final pages = await repo.pagesOf(doc);
    await repo.rewritePages(doc, [pages[1], pages[0], pages[2]], password: 'secret');
    final after = (await repo.get(doc.id))!;
    expect(after.isProtected, isTrue);
    expect(latin1.decode(repo.pdfOf(after).readAsBytesSync()), contains('/Encrypt'));
  });

  test('refuses an empty page list', () async {
    final doc = await saved();
    expect(() => repo.rewritePages(doc, []), throwsA(anything));
    expect((await repo.get(doc.id))!.pageCount, 3);
  });
}
