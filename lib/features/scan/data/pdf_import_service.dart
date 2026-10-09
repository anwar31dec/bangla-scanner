import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/app_exception.dart';
import '../../../core/widgets/progress_dialog.dart';

/// Renders the pages of a PDF file to JPEGs so they can be edited like
/// scanned pages. Rendering is done by the platform (Android `PdfRenderer`,
/// iOS Core Graphics) on a background thread, one page per call, so the
/// UI can show progress and a huge PDF never has to fit in memory at once.
class PdfImportService {
  PdfImportService({MethodChannel? channel}) : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.codeinherit.banglascanner/pdf';

  /// Longest edge of a rendered page, about 200 dpi on A4 (the medium
  /// export quality), so an imported page is as sharp as a scanned one.
  static const renderMaxEdge = 2339;

  /// Pages beyond this are not imported; the editor is not made for books.
  static const maxPages = 100;

  final MethodChannel _channel;

  /// Number of pages in the PDF at [path]. Throws [AppErrorKind.pdfLocked]
  /// for a password-protected file and [AppErrorKind.corruptFile] for
  /// anything that is not a readable PDF.
  Future<int> pageCount(String path) async {
    final id = await _open(path);
    try {
      return id.pageCount;
    } finally {
      await _close(id.id);
    }
  }

  /// Renders the first [maxPages] pages of the PDF at [path] into [outDir]
  /// (`page_001.jpg`, …) and returns their paths in order.
  Future<List<String>> renderPages(String path, Directory outDir, {ProgressReporter? onProgress}) async {
    await outDir.create(recursive: true);
    final doc = await _open(path);
    try {
      final total = doc.pageCount.clamp(0, maxPages);
      if (total == 0) throw const AppException(AppErrorKind.corruptFile, 'PDF has no pages');
      onProgress?.call(0, total);
      final pages = <String>[];
      for (var i = 0; i < total; i++) {
        final target = p.join(outDir.path, 'page_${(i + 1).toString().padLeft(3, '0')}.jpg');
        try {
          final rendered = await _channel.invokeMethod<String>('render', {
            'id': doc.id,
            'index': i,
            'maxEdge': renderMaxEdge,
            'path': target,
          });
          if (rendered == null) throw const AppException(AppErrorKind.corruptFile, 'Page did not render');
          pages.add(rendered);
        } on PlatformException catch (e) {
          throw AppException.from(e);
        }
        onProgress?.call(i + 1, total);
      }
      return pages;
    } finally {
      await _close(doc.id);
    }
  }

  Future<({int id, int pageCount})> _open(String path) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('open', {'path': path});
      final id = result?['id'], count = result?['pageCount'];
      if (id is! int || count is! int) throw const AppException(AppErrorKind.corruptFile, 'Bad open result');
      return (id: id, pageCount: count);
    } on PlatformException catch (e) {
      throw AppException.from(e);
    } on MissingPluginException catch (e) {
      throw AppException(AppErrorKind.generic, e);
    }
  }

  Future<void> _close(int id) async {
    try {
      await _channel.invokeMethod<void>('close', {'id': id});
    } catch (_) {
      // Nothing the user can do about it.
    }
  }
}

final pdfImportServiceProvider = Provider<PdfImportService>((ref) => PdfImportService());
