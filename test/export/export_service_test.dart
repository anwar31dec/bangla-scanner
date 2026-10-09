import 'dart:io';
import 'dart:isolate';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/core/utils/app_exception.dart';
import 'package:banglascanner/features/export/data/export_service.dart';
import 'package:banglascanner/features/library/data/document_repository.dart';
import 'package:banglascanner/features/export/data/pdf_builder.dart';
import 'package:banglascanner/features/scan/data/draft_document.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';
import '../ocr/fake_engine.dart';
import 'pdf_text_layer_test.dart' show inflatedStreams;

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
    repo = DocumentRepository(db, paths, loadFont: () => File(TextLayerFont.asset).readAsBytes());
    service = ExportService(repo, paths, ocrEngine: FakeOcrEngine());
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

  test('saves when the progress callback holds something unsendable', () async {
    // Screens pass a callback that captures their State, which cannot be
    // sent to an isolate; it must never end up in the isolate message.
    final unsendable = ReceivePort();
    addTearDown(unsendable.close);
    final doc = await service.save(
      draft: await draftWith(2),
      name: 'Scan',
      format: SaveFormat.pdf,
      quality: ExportQuality.low,
      onProgress: (_, _) => unsendable.hashCode,
    );
    expect(doc.pageCount, 2);
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

  test('searchable PDF: text is recognized, stored, searchable and drawn into the PDF', () async {
    final ocrProgress = <(int, int)>[];
    final doc = await service.save(
      draft: await draftWith(2),
      name: 'Shop',
      format: SaveFormat.pdf,
      quality: ExportQuality.low,
      ocrLanguage: OcrLanguage.both,
      onOcrProgress: (d, t) => ocrProgress.add((d, t)),
    );
    expect(ocrProgress.first, (0, 2));
    expect(ocrProgress.last, (2, 2));
    expect(doc.hasText, isTrue);

    final texts = await repo.pageTextsOf(doc);
    expect(texts.length, 2);
    expect(texts[1]!.text, 'Invoice 2\nমোট টাকা ৫০০');
    expect(texts[1]!.words.single.text, 'Invoice');
    expect((await db.pageTextsOf(doc.id)).map((r) => r.language), everyElement(OcrLanguage.both));

    // The PDF carries the words invisibly.
    final pdf = repo.pdfOf(doc).readAsBytesSync();
    expect(RegExp(r'\b3 Tr\b').allMatches(inflatedStreams(pdf)).length, 2);

    // Found by a word inside, not only by name; with an excerpt.
    expect((await repo.watchAll(search: 'টাকা').first).map((d) => d.id), [doc.id]);
    expect((await repo.watchAll(search: 'invoice 2').first).map((d) => d.id), [doc.id]);
    expect(await repo.watchAll(search: 'nothing').first, isEmpty);
    final matches = await repo.watchTextMatches('টাকা').first;
    expect(DocumentRepository.textSnippet(matches[doc.id]!, 'টাকা'), 'Invoice 1 মোট টাকা ৫০০');
    expect(DocumentRepository.textSnippet('${'a' * 100} needle ${'b' * 100}', 'needle', radius: 4), '…aaa needle bbb…');

    // Re-saving the edited document without OCR drops the stale text.
    final again = await service.save(
      draft: await draftWith(1, existingId: doc.id),
      name: 'Shop',
      format: SaveFormat.pdf,
      quality: ExportQuality.low,
    );
    expect(again.hasText, isFalse);
    expect(await db.pageTextsOf(doc.id), isEmpty);
    expect(await repo.watchAll(search: 'টাকা').first, isEmpty);
  });

  test('deleting a document removes its text', () async {
    final doc = await service.save(
      draft: await draftWith(1),
      name: 'Gone',
      format: SaveFormat.jpeg,
      quality: ExportQuality.low,
      ocrLanguage: OcrLanguage.english,
    );
    expect(await db.pageTextsOf(doc.id), hasLength(1));
    await repo.delete(doc);
    expect(await db.pageTextsOf(doc.id), isEmpty);
  });

  test('saving with OCR but no engine fails cleanly', () async {
    final noEngine = ExportService(repo, paths);
    await expectLater(
      noEngine.save(draft: await draftWith(1), name: 'X', format: SaveFormat.pdf, quality: ExportQuality.low, ocrLanguage: OcrLanguage.bangla),
      throwsA(isA<AppException>()),
    );
    expect(await db.watchDocuments().first, isEmpty);
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
