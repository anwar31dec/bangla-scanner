import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Central place for every directory the app writes to.
///
/// Library documents live in `<app documents>/library/<documentId>/`:
/// ```
/// pages/page_001.jpg …   final processed pages (also the JPEG output)
/// document.pdf           only for PDF documents
/// thumb.jpg              list thumbnail
/// ```
/// Only paths relative to the documents directory are stored in the
/// database, because the absolute iOS container path changes on updates.
class AppPaths {
  AppPaths(this.documentsDir, this.tempDir);

  final Directory documentsDir;
  final Directory tempDir;

  static Future<AppPaths> resolve() async =>
      AppPaths(await getApplicationDocumentsDirectory(), await getTemporaryDirectory());

  Directory get libraryDir => Directory(p.join(documentsDir.path, 'library'));

  /// Scratch space for the document being scanned/edited.
  Directory get workDir => Directory(p.join(tempDir.path, 'work'));

  /// Files prepared for sharing (named copies). Cleared on each share.
  Directory get shareDir => Directory(p.join(tempDir.path, 'share'));

  /// Folder flutter_tesseract_ocr reads language models from.
  Directory get tessdataDir => Directory(p.join(documentsDir.path, 'tessdata'));

  /// Saved signatures (`<uuid>.png`, transparent background).
  Directory get signaturesDir => Directory(p.join(documentsDir.path, 'signatures'));

  /// Backup zips being written and backups being unpacked. Cleared on start.
  Directory get backupDir => Directory(p.join(tempDir.path, 'backup'));

  /// Files handed to the app by other apps (share / "Open with"), copied
  /// here by the platform side until the editor has taken them over.
  Directory get receivedDir => Directory(p.join(tempDir.path, 'received'));

  String relative(String absolute) => p.relative(absolute, from: documentsDir.path);

  String absolute(String relative) => p.join(documentsDir.path, relative);
}
