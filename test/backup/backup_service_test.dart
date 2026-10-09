import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/core/storage/app_database.dart';
import 'package:banglascanner/core/storage/app_paths.dart';
import 'package:banglascanner/core/utils/app_exception.dart';
import 'package:banglascanner/features/backup/data/backup_manifest.dart';
import 'package:banglascanner/features/backup/data/backup_service.dart';
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
  late BackupService backup;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('bs_backup');
    paths = AppPaths(
      Directory(p.join(root.path, 'docs'))..createSync(),
      Directory(p.join(root.path, 'tmp'))..createSync(),
    );
    db = AppDatabase(NativeDatabase.memory());
    repo = DocumentRepository(db, paths);
    backup = BackupService(db, paths, appVersion: 'test');
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  Future<DocumentRow> saveDoc(
    String name, {
    SaveFormat format = SaveFormat.pdf,
    int pages = 2,
    String? folderId,
  }) async {
    final dir = Directory(p.join(root.path, 'work', name))..createSync(recursive: true);
    final list = <DraftPage>[];
    for (var i = 0; i < pages; i++) {
      final f = File(p.join(dir.path, 'p$i.jpg'))..writeAsBytesSync(fakeDocumentJpeg(width: 200, height: 260));
      list.add(DraftPage(id: '$name-$i', imagePath: f.path));
    }
    return ExportService(repo, paths).save(
      draft: DraftDocument(workDirPath: dir.path, pages: list),
      name: name,
      format: format,
      quality: ExportQuality.low,
      folderId: folderId,
    );
  }

  test('backup zip contains a manifest and every document file, uncompressed', () async {
    final folder = await repo.createFolder('Bills');
    final a = await saveDoc('Alpha', folderId: folder.id);
    final b = await saveDoc('Beta', format: SaveFormat.jpeg, pages: 3);
    await repo.setFavorite(b.id, true);

    final progress = <(int, int)>[];
    final zip = await backup.createBackup(onProgress: (d, t) => progress.add((d, t)));
    expect(zip.existsSync(), isTrue);
    expect(p.basename(zip.path), startsWith('BanglaScanner-Backup-'));
    expect(progress.first, (0, 2));
    expect(progress.last, (2, 2));

    final archive = ZipDecoder().decodeBytes(zip.readAsBytesSync());
    final names = archive.files.map((f) => f.name).toSet();
    expect(names, contains('manifest.json'));
    expect(names, contains('library/${a.id}/document.pdf'));
    expect(names, contains('library/${a.id}/pages/page_001.jpg'));
    expect(names, contains('library/${a.id}/thumb.jpg'));
    expect(names, contains('library/${b.id}/pages/page_003.jpg'));
    expect(names.where((n) => n.startsWith('library/${b.id}/')).any((n) => n.endsWith('document.pdf')), isFalse);

    final manifest = BackupManifest.fromJson(
      jsonDecode(utf8.decode(archive.find('manifest.json')!.readBytes()!)) as Map<String, Object?>,
    );
    expect(manifest.appVersion, 'test');
    expect(manifest.folders.map((f) => f.name), ['Bills']);
    expect(manifest.documents.length, 2);
    final beta = manifest.documents.firstWhere((d) => d.id == b.id);
    expect(beta.format, SaveFormat.jpeg);
    expect(beta.pageCount, 3);
    expect(beta.isFavorite, isTrue);
    expect(manifest.documents.firstWhere((d) => d.id == a.id).folderId, folder.id);

    // Already-compressed files are stored, not deflated.
    final pdf = archive.find('library/${a.id}/document.pdf')!;
    expect(pdf.readBytes()!.length, File(p.join(repo.dirOf(a).path, 'document.pdf')).lengthSync());
  });

  test('restore into an empty library brings documents, folders and files back', () async {
    final folder = await repo.createFolder('Bills');
    final a = await saveDoc('Alpha', folderId: folder.id);
    final b = await saveDoc('Beta', format: SaveFormat.jpeg, pages: 3);
    final zip = await backup.createBackup();
    final zipCopy = File(p.join(root.path, 'kept.zip'))..writeAsBytesSync(zip.readAsBytesSync());

    // Wipe the library like a fresh install.
    await repo.delete(a);
    await repo.delete(b);
    await repo.deleteFolder(folder.id);
    expect(await db.allDocuments(), isEmpty);

    final inspected = await backup.inspect(zipCopy.path);
    expect(inspected.documents.length, 2);

    final progress = <(int, int)>[];
    final summary = await backup.restore(zipCopy.path, onProgress: (d, t) => progress.add((d, t)));
    expect(summary.added, 2);
    expect(summary.skipped, 0);
    expect(progress.last, (2, 2));

    final docs = await db.allDocuments();
    expect(docs.map((d) => d.name).toSet(), {'Alpha', 'Beta'});
    final restoredA = docs.firstWhere((d) => d.id == a.id);
    expect(restoredA.folderId, folder.id);
    expect(restoredA.dirPath, a.dirPath);
    expect(await repo.isIntact(restoredA), isTrue);
    expect((await repo.pagesOf(restoredA)).length, 2);
    final restoredB = docs.firstWhere((d) => d.id == b.id);
    expect(restoredB.format, SaveFormat.jpeg);
    expect((await repo.pagesOf(restoredB)).length, 3);
    expect(repo.thumbnailOf(restoredB).existsSync(), isTrue);
    expect((await db.allFolders()).map((f) => f.name), ['Bills']);
    // Staging is cleaned up.
    expect(paths.backupDir.listSync().whereType<Directory>(), isEmpty);
  });

  test('restore keeps documents that already exist and only adds the missing ones', () async {
    final a = await saveDoc('Alpha');
    final b = await saveDoc('Beta');
    final zip = await backup.createBackup();
    final zipCopy = File(p.join(root.path, 'kept.zip'))..writeAsBytesSync(zip.readAsBytesSync());

    await repo.delete(b);
    await repo.rename(a.id, 'Alpha renamed');

    final summary = await backup.restore(zipCopy.path);
    expect(summary.added, 1);
    expect(summary.skipped, 1);
    final docs = await db.allDocuments();
    expect(docs.map((d) => d.name).toSet(), {'Alpha renamed', 'Beta'});
    expect(await repo.isIntact(docs.firstWhere((d) => d.id == b.id)), isTrue);
  });

  test('a zip that is not a backup is rejected', () async {
    final notZip = File(p.join(root.path, 'x.zip'))..writeAsStringSync('hello');
    expect(
      () => backup.inspect(notZip.path),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.invalidBackup)),
    );

    final encoder = ZipFileEncoder()..create(p.join(root.path, 'other.zip'));
    encoder.addArchiveFile(ArchiveFile.string('readme.txt', 'nope'));
    await encoder.close();
    expect(
      () => backup.inspect(p.join(root.path, 'other.zip')),
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', AppErrorKind.invalidBackup)),
    );
  });

  test('entries that try to escape the library folder are ignored', () async {
    final manifest = BackupManifest(
      createdAt: DateTime.now(),
      appVersion: 'x',
      folders: const [],
      documents: [
        BackupDocument(
          id: 'evil',
          name: 'Evil',
          format: SaveFormat.jpeg,
          pageCount: 1,
          sizeBytes: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFavorite: false,
          folderId: null,
          isProtected: false,
        ),
      ],
    );
    final zipPath = p.join(root.path, 'evil.zip');
    final encoder = ZipFileEncoder()..create(zipPath);
    encoder.addArchiveFile(ArchiveFile.string('manifest.json', jsonEncode(manifest.toJson())));
    encoder.addArchiveFile(ArchiveFile.string('library/evil/../../escaped.txt', 'bad'));
    encoder.addArchiveFile(ArchiveFile.string('../escaped2.txt', 'bad'));
    encoder.addArchiveFile(
      ArchiveFile.bytes('library/evil/pages/page_001.jpg', fakeDocumentJpeg(width: 50, height: 50)),
    );
    await encoder.close();

    final summary = await backup.restore(zipPath);
    expect(summary.added, 1);
    expect(File(p.join(root.path, 'escaped.txt')).existsSync(), isFalse);
    expect(File(p.join(root.path, 'escaped2.txt')).existsSync(), isFalse);
    expect(File(p.join(paths.libraryDir.path, 'escaped.txt')).existsSync(), isFalse);
    expect(File(p.join(paths.libraryDir.path, 'evil', 'pages', 'page_001.jpg')).existsSync(), isTrue);
  });

  test('a document whose files are missing from the zip is not added', () async {
    final manifest = BackupManifest(
      createdAt: DateTime.now(),
      appVersion: 'x',
      folders: const [],
      documents: [
        BackupDocument(
          id: 'ghost',
          name: 'Ghost',
          format: SaveFormat.pdf,
          pageCount: 1,
          sizeBytes: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFavorite: false,
          folderId: 'nofolder',
          isProtected: false,
        ),
      ],
    );
    final zipPath = p.join(root.path, 'ghost.zip');
    final encoder = ZipFileEncoder()..create(zipPath);
    encoder.addArchiveFile(ArchiveFile.string('manifest.json', jsonEncode(manifest.toJson())));
    await encoder.close();

    final summary = await backup.restore(zipPath);
    expect(summary.added, 0);
    expect(await db.allDocuments(), isEmpty);
  });
}
