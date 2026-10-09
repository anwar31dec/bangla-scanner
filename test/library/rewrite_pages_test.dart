import 'dart:convert';
import 'dart:io';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/features/export/data/export_service.dart';
import 'package:banglascanner/features/export/data/pdf_builder.dart';
import 'package:banglascanner/features/ocr/data/ocr_result.dart';
import 'package:banglascanner/features/library/data/document_repository.dart';
import 'package:banglascanner/features/scan/data/draft_document.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../export/pdf_text_layer_test.dart' show inflatedStreams;
import '../helpers.dart';
import '../ocr/fake_engine.dart';

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
    repo = DocumentRepository(db, paths, loadFont: () => File(TextLayerFont.asset).readAsBytes());
    service = ExportService(repo, paths, ocrEngine: FakeOcrEngine(textFor: (i) => 'Page ${i + 1} text'));
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  Future<DocumentRow> saved({String? password, OcrLanguage? ocr}) async {
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
      ocrLanguage: ocr,
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

  test('recognized text follows its page when pages are reordered or removed', () async {
    final doc = await saved(ocr: OcrLanguage.english);
    expect(doc.hasText, isTrue);
    final pages = await repo.pagesOf(doc);
    await repo.rewritePages(doc, [pages[2], pages[0]]);

    final after = (await repo.get(doc.id))!;
    expect(after.hasText, isTrue);
    final texts = await repo.pageTextsOf(after);
    expect(texts.map((t) => t?.text), ['Page 3 text', 'Page 1 text']);
    expect(texts.map((t) => t?.words.single.text), ['Page', 'Page']);
    expect((await db.pageTextsOf(doc.id)).map((r) => r.language), everyElement(OcrLanguage.english));
    expect(RegExp(r'\b3 Tr\b').allMatches(inflatedStreams(repo.pdfOf(after).readAsBytesSync())).length, 2);
    expect((await repo.watchAll(search: 'page 2').first), isEmpty);
    expect((await repo.watchAll(search: 'page 3').first).map((d) => d.id), [doc.id]);
  });

  test('rebuildPdf adds the text layer to an existing PDF and keeps the file whole', () async {
    final doc = await saved();
    expect(inflatedStreams(repo.pdfOf(doc).readAsBytesSync()), isNot(contains('3 Tr')));
    await repo.setPageTexts(doc.id, [
      const PageText(text: 'hello world', words: [OcrWord('hello', left: 0.1, top: 0.1, right: 0.3, bottom: 0.15)]),
      null,
      const PageText(text: 'third'),
    ], OcrLanguage.english);
    expect((await repo.get(doc.id))!.hasText, isTrue);

    await repo.rebuildPdf(doc);
    final after = (await repo.get(doc.id))!;
    expect(RegExp(r'\b3 Tr\b').allMatches(inflatedStreams(repo.pdfOf(after).readAsBytesSync())).length, 1);
    expect(after.sizeBytes, repo.pdfOf(after).lengthSync());
    expect(after.pageCount, 3);
    expect(File('${repo.pdfOf(after).path}.tmp').existsSync(), isFalse);

    // Clearing the text clears the flag.
    await repo.setPageTexts(doc.id, const [], OcrLanguage.english);
    expect((await repo.get(doc.id))!.hasText, isFalse);
  });

  test('refuses an empty page list', () async {
    final doc = await saved();
    expect(() => repo.rewritePages(doc, []), throwsA(anything));
    expect((await repo.get(doc.id))!.pageCount, 3);
  });
}
