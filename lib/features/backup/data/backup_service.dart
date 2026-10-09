import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/app_info.dart' as app_info;
import '../../../core/models/enums.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/app_paths.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/widgets/progress_dialog.dart';
import '../../library/data/document_repository.dart';
import '../../ocr/data/ocr_result.dart';
import 'backup_manifest.dart';

/// Outcome of a restore.
class RestoreSummary {
  const RestoreSummary({required this.added, required this.skipped});

  /// Documents copied into the library.
  final int added;

  /// Documents left alone because the library already had them.
  final int skipped;
}

/// Exports the whole library as one zip and imports such zips again.
///
/// The zip is written and read in a background isolate; only the database
/// rows are touched on the main isolate. Page JPEGs and PDFs are stored
/// uncompressed in the zip (they are compressed already), which keeps a
/// backup of hundreds of pages fast.
class BackupService {
  BackupService(this._db, this._paths, {required this.appVersion});

  final AppDatabase _db;
  final AppPaths _paths;
  final String appVersion;

  /// Name of the zip, e.g. `BanglaScanner-Backup-06-10-2026-14-05.zip`.
  /// Latin digits, no locale data needed.
  static String backupFileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'BanglaScanner-Backup-${two(now.day)}-${two(now.month)}-${now.year}-${two(now.hour)}-${two(now.minute)}.zip';
  }

  /// Writes a backup of every document into [AppPaths.backupDir] and returns
  /// the zip. [onProgress] counts documents.
  Future<File> createBackup({ProgressReporter? onProgress}) async {
    final docs = await _db.allDocuments();
    final folders = await _db.allFolders();

    final entries = <_ZipEntry>[];
    final included = <BackupDocument>[];
    // Which document each zip entry belongs to, for per-document progress.
    final docOfEntry = <int>[];
    for (final doc in docs) {
      final dir = Directory(_paths.absolute(doc.dirPath));
      if (!await dir.exists()) continue;
      final files = await dir.list(recursive: true, followLinks: false).where((e) => e is File).cast<File>().toList();
      if (files.isEmpty) continue;
      final zipFolder = '${BackupManifest.libraryFolder}/${doc.id}';
      for (final f in files) {
        final rel = p.relative(f.path, from: dir.path);
        entries.add(_ZipEntry(f.path, '$zipFolder/${p.posix.joinAll(p.split(rel))}'));
        docOfEntry.add(included.length);
      }
      final texts = await _db.pageTextsOf(doc.id);
      included.add(
        BackupDocument(
          id: doc.id,
          name: doc.name,
          format: doc.format,
          pageCount: doc.pageCount,
          sizeBytes: doc.sizeBytes,
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
          isFavorite: doc.isFavorite,
          folderId: doc.folderId,
          isProtected: doc.isProtected,
          texts: [
            for (final t in texts)
              BackupPageText(
                pageIndex: t.pageIndex,
                text: PageText(text: t.content, words: PageText.wordsFromJson(t.words)),
                language: t.language,
              ),
          ],
        ),
      );
    }
    if (included.isEmpty) throw const AppException(AppErrorKind.generic, 'Nothing to back up');

    final manifest = BackupManifest(
      createdAt: DateTime.now(),
      appVersion: appVersion,
      folders: [for (final f in folders) BackupFolder(id: f.id, name: f.name, createdAt: f.createdAt)],
      documents: included,
    );

    final outDir = _paths.backupDir;
    await outDir.create(recursive: true);
    final zip = File(p.join(outDir.path, backupFileName(manifest.createdAt)));
    if (await zip.exists()) await zip.delete();

    try {
      onProgress?.call(0, included.length);
      await _runWithProgress(
        _ZipJob(zip.path, entries, jsonEncode(manifest.toJson())),
        _writeZip,
        // Progress arrives per file; show it per document.
        (filesDone) =>
            onProgress?.call(filesDone >= entries.length ? included.length : docOfEntry[filesDone], included.length),
      );
      onProgress?.call(included.length, included.length);
      return zip;
    } catch (e) {
      try {
        if (await zip.exists()) await zip.delete();
      } catch (_) {}
      throw AppException.from(e);
    }
  }

  /// Reads the manifest of a backup without unpacking it. Throws
  /// [AppErrorKind.invalidBackup] for anything that is not our zip.
  Future<BackupManifest> inspect(String zipPath) async {
    try {
      final json = await Isolate.run(() => _readManifest(zipPath));
      return BackupManifest.fromJson(jsonDecode(json) as Map<String, Object?>);
    } on FormatException catch (e) {
      // Includes ArchiveException: a file that is not a zip at all.
      throw AppException(AppErrorKind.invalidBackup, e);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Adds the documents and folders of the backup at [zipPath] that the
  /// library does not have yet. Existing documents (same id) are kept as
  /// they are. [onProgress] counts documents.
  Future<RestoreSummary> restore(String zipPath, {ProgressReporter? onProgress}) async {
    final manifest = await inspect(zipPath);
    final staging = Directory(p.join(_paths.backupDir.path, 'restore_${DateTime.now().microsecondsSinceEpoch}'));
    try {
      await staging.create(recursive: true);
      final existing = {for (final d in await _db.allDocuments()) d.id};
      final toAdd = [
        for (final d in manifest.documents)
          if (!existing.contains(d.id)) d,
      ];
      final total = toAdd.length;
      onProgress?.call(0, total);

      // Unpack only what will be added.
      final wanted = {for (final d in toAdd) d.zipFolder};
      await _runWithProgress(_UnzipJob(zipPath, staging.path, wanted.toList()), _extract, (filesDone) {});

      // Folders first so documents can point at them.
      final knownFolders = {for (final f in await _db.allFolders()) f.id};
      for (final f in manifest.folders) {
        if (knownFolders.add(f.id)) {
          await _db.insertFolder(FolderRow(id: f.id, name: f.name, createdAt: f.createdAt));
        }
      }

      var added = 0;
      for (var i = 0; i < toAdd.length; i++) {
        final doc = toAdd[i];
        final from = Directory(p.join(staging.path, BackupManifest.libraryFolder, doc.id));
        if (!await _looksLikeDocument(from, doc)) continue;
        final target = Directory(p.join(_paths.libraryDir.path, doc.id));
        await target.parent.create(recursive: true);
        // A folder without a database row is a leftover from a failed save.
        if (await target.exists()) await target.delete(recursive: true);
        await from.rename(target.path);
        await _db.upsertDocument(
          DocumentsCompanion(
            id: Value(doc.id),
            name: Value(doc.name),
            format: Value(doc.format),
            dirPath: Value(_paths.relative(target.path)),
            pageCount: Value(doc.pageCount),
            sizeBytes: Value(doc.sizeBytes),
            createdAt: Value(doc.createdAt),
            updatedAt: Value(doc.updatedAt),
            isFavorite: Value(doc.isFavorite),
            folderId: Value(doc.folderId != null && knownFolders.contains(doc.folderId) ? doc.folderId : null),
            isProtected: Value(doc.isProtected),
          ),
        );
        if (doc.texts.isNotEmpty) {
          await _db.setPageTexts(doc.id, [
            for (final t in doc.texts)
              if (t.pageIndex >= 0 && t.pageIndex < doc.pageCount)
                PageTextsCompanion.insert(
                  documentId: doc.id,
                  pageIndex: t.pageIndex,
                  content: t.text.text,
                  words: Value(t.text.wordsJson),
                  language: t.language,
                ),
          ]);
        }
        added++;
        onProgress?.call(i + 1, total);
      }
      return RestoreSummary(added: added, skipped: manifest.documents.length - added);
    } catch (e) {
      throw AppException.from(e);
    } finally {
      try {
        if (await staging.exists()) await staging.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// A restored folder must contain what the document needs (pages, or the
  /// PDF), otherwise the library would show a broken document.
  Future<bool> _looksLikeDocument(Directory dir, BackupDocument doc) async {
    if (!await dir.exists()) return false;
    final pdf = File(p.join(dir.path, DocumentRepository.pdfFileName));
    final pages = Directory(p.join(dir.path, DocumentRepository.pagesFolder));
    final hasPages = await pages.exists() && await pages.list().any((e) => e is File && e.path.endsWith('.jpg'));
    return doc.format == SaveFormat.pdf ? await pdf.exists() : hasPages;
  }

  /// Runs [body] in a new isolate and forwards the ints it posts to
  /// [onProgress]. Completes when the isolate sends `null`; rethrows errors.
  static Future<void> _runWithProgress(
    Object job,
    Future<void> Function(Object job, SendPort progress) body,
    void Function(int done) onProgress,
  ) async {
    final port = ReceivePort();
    final isolate = await Isolate.spawn(_isolateMain, (port.sendPort, job, body));
    try {
      await for (final message in port) {
        if (message == null) return;
        if (message is int) {
          onProgress(message);
        } else if (message is _IsolateError) {
          throw message.error;
        }
      }
    } finally {
      port.close();
      isolate.kill();
    }
  }

  static Future<void> _isolateMain((SendPort, Object, Future<void> Function(Object, SendPort)) args) async {
    final (port, job, body) = args;
    try {
      await body(job, port);
      port.send(null);
    } catch (e) {
      // Only simple values cross isolates; keep the message, not the object.
      port.send(_IsolateError(e is FileSystemException ? e : StateError(e.toString())));
    }
  }

  static Future<void> _writeZip(Object jobArg, SendPort progress) async {
    final job = jobArg as _ZipJob;
    final encoder = ZipFileEncoder()..create(job.zipPath, level: ZipFileEncoder.store);
    try {
      encoder.addArchiveFile(ArchiveFile.string(BackupManifest.fileName, job.manifestJson));
      for (var i = 0; i < job.entries.length; i++) {
        final e = job.entries[i];
        await encoder.addFile(File(e.sourcePath), e.zipPath, ZipFileEncoder.store);
        progress.send(i + 1);
      }
    } finally {
      await encoder.close();
    }
  }

  static String _readManifest(String zipPath) {
    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final file = archive.find(BackupManifest.fileName);
      if (file == null || !file.isFile) throw const FormatException('No manifest');
      final bytes = file.readBytes();
      if (bytes == null) throw const FormatException('Empty manifest');
      return utf8.decode(bytes);
    } finally {
      input.closeSync();
    }
  }

  static Future<void> _extract(Object jobArg, SendPort progress) async {
    final job = jobArg as _UnzipJob;
    final input = InputFileStream(job.zipPath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final wanted = job.folders.toSet();
      var done = 0;
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final name = entry.name.replaceAll('\\', '/');
        final parts = p.posix.split(name);
        // Zip slip: an entry may not escape the staging folder.
        if (parts.length < 3 ||
            parts.first != BackupManifest.libraryFolder ||
            p.posix.isAbsolute(name) ||
            parts.any((s) => s == '..' || s == '.' || s.isEmpty)) {
          continue;
        }
        if (!wanted.contains('${parts[0]}/${parts[1]}')) continue;
        final target = File(p.joinAll([job.outDir, ...parts]));
        await target.parent.create(recursive: true);
        final out = OutputFileStream(target.path);
        try {
          entry.writeContent(out);
        } finally {
          await out.close();
        }
        progress.send(++done);
      }
    } finally {
      input.closeSync();
    }
  }
}

class _ZipEntry {
  const _ZipEntry(this.sourcePath, this.zipPath);
  final String sourcePath;
  final String zipPath;
}

class _ZipJob {
  const _ZipJob(this.zipPath, this.entries, this.manifestJson);
  final String zipPath;
  final List<_ZipEntry> entries;
  final String manifestJson;
}

class _UnzipJob {
  const _UnzipJob(this.zipPath, this.outDir, this.folders);
  final String zipPath;
  final String outDir;
  final List<String> folders;
}

class _IsolateError {
  const _IsolateError(this.error);
  final Object error;
}

final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return BackupService(ref.watch(appDatabaseProvider), paths, appVersion: app_info.appVersion);
});
