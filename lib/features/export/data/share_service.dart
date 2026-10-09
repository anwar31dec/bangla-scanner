import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../../core/models/enums.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/app_paths.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../library/data/document_repository.dart';

/// Where "Save to phone" put the file(s).
enum SaveDestination { downloads, files, cancelled }

/// Sharing (WhatsApp, Messenger, email…) and saving copies to device storage.
class ShareService {
  ShareService(this._repo, this._paths);

  final DocumentRepository _repo;
  final AppPaths _paths;

  static const _channel = MethodChannel('com.codeinherit.banglascanner/storage');

  /// Opens the system share sheet with the document's PDF or JPEG pages.
  Future<void> shareDocument(DocumentRow doc, {Rect? origin}) => shareDocuments([doc], origin: origin);

  /// Opens the system share sheet with the files of several documents.
  Future<void> shareDocuments(List<DocumentRow> docs, {Rect? origin}) async {
    final files = await _namedCopies(docs);
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final f in files) XFile(f.path, mimeType: _mimeOf(f.path))],
        subject: docs.length == 1 ? docs.first.name : null,
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Shares arbitrary files (e.g. a backup zip) through the system sheet.
  Future<void> shareFiles(List<File> files, {String? subject, Rect? origin}) => SharePlus.instance.share(
        ShareParams(
          files: [for (final f in files) XFile(f.path, mimeType: _mimeOf(f.path))],
          subject: subject,
          sharePositionOrigin: origin,
        ),
      );

  /// Saves arbitrary files (e.g. a backup zip) to Downloads/Bangla Scanner
  /// (Android) or a location the user picks in the Files app (iOS).
  Future<SaveDestination> saveFilesToDevice(List<File> files) => _saveToDevice(files);

  /// Shares plain text (OCR result).
  Future<void> shareText(String text, {String? subject, Rect? origin}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject, sharePositionOrigin: origin));

  /// Saves a copy of the document to Downloads/Bangla Scanner (Android) or
  /// a location the user picks in the Files app (iOS).
  Future<SaveDestination> saveDocumentToDevice(DocumentRow doc) async => _saveToDevice(await _namedCopies([doc]));

  /// Saves OCR text as a .txt file to device storage.
  Future<SaveDestination> saveTextToDevice(String text, String baseName) async {
    final dir = await _freshShareDir();
    final file = File(p.join(dir.path, '${Formatters.safeFileName(baseName)}.txt'));
    await file.writeAsString(text, flush: true);
    return _saveToDevice([file]);
  }

  Future<SaveDestination> _saveToDevice(List<File> files) async {
    try {
      if (Platform.isAndroid) {
        for (final f in files) {
          await _channel.invokeMethod<String>('saveToDownloads', {
            'path': f.path,
            'name': p.basename(f.path),
            'mime': _mimeOf(f.path),
          });
        }
        return SaveDestination.downloads;
      }
      final ok = await _channel.invokeMethod<bool>('exportToFiles', {'paths': [for (final f in files) f.path]});
      return ok == true ? SaveDestination.files : SaveDestination.cancelled;
    } on PlatformException catch (e) {
      throw AppException.from(e);
    }
  }

  /// Copies output files into a temp folder with friendly names
  /// ("Scan 06-10-2026.pdf", "Scan 06-10-2026 (2).jpg"), because internal
  /// files are named document.pdf / page_001.jpg. Two documents with the
  /// same name get a numbered suffix.
  Future<List<File>> _namedCopies(List<DocumentRow> docs) async {
    final dir = await _freshShareDir();
    final used = <String>{};
    final copies = <File>[];
    for (final doc in docs) {
      final outputs = await _repo.outputFilesOf(doc);
      if (outputs.isEmpty || !(await _repo.isIntact(doc))) {
        throw const AppException(AppErrorKind.missingFile);
      }
      var base = Formatters.safeFileName(doc.name);
      for (var n = 2; !used.add(base.toLowerCase()); n++) {
        base = '${Formatters.safeFileName(doc.name)} $n';
      }
      for (var i = 0; i < outputs.length; i++) {
        final ext = doc.format == SaveFormat.pdf ? '.pdf' : '.jpg';
        final suffix = outputs.length > 1 ? ' (${i + 1})' : '';
        copies.add(await outputs[i].copy(p.join(dir.path, '$base$suffix$ext')));
      }
    }
    return copies;
  }

  Future<Directory> _freshShareDir() async {
    final dir = _paths.shareDir;
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    return dir;
  }

  static String _mimeOf(String path) => switch (p.extension(path).toLowerCase()) {
        '.pdf' => 'application/pdf',
        '.jpg' || '.jpeg' => 'image/jpeg',
        '.txt' => 'text/plain',
        '.zip' => 'application/zip',
        '.png' => 'image/png',
        _ => 'application/octet-stream',
      };
}

final shareServiceProvider = FutureProvider<ShareService>((ref) async {
  return ShareService(await ref.watch(documentRepositoryProvider.future), await ref.watch(appPathsProvider.future));
});
