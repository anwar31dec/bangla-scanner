import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/progress_dialog.dart';
import '../application/draft_controller.dart';
import '../data/pdf_import_service.dart';
import '../data/scanner_service.dart';
import 'flash_camera_screen.dart';

/// Where new pages come from.
enum PageSource {
  /// The native document scanner.
  scanner,

  /// The in-app camera whose flash fires only when a photo is taken.
  flashCamera,
  gallery,

  /// Pages rendered from a PDF file.
  pdf,
}

/// File types other apps may hand us.
extension ReceivedFileType on String {
  bool get isPdfFile => p.extension(this).toLowerCase() == '.pdf';

  bool get isImageFile => const {'.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif', '.bmp', '.gif'}
      .contains(p.extension(this).toLowerCase());
}

/// UI-level orchestration of scanning/importing: permissions, the native
/// scanner, error messages and navigation to the editor.
class ScanActions {
  ScanActions._();

  /// Big "Scan" button: scan pages, then open the editor.
  static Future<void> scanNew(BuildContext context, WidgetRef ref) async {
    final paths = await scanPages(context, ref);
    if (paths == null || !context.mounted) return;
    await ref.read(draftProvider.notifier).startNew(paths);
    await ref.read(scannerServiceProvider).cleanCache();
    if (context.mounted) context.push(Routes.editor);
  }

  /// "Flash Scan": take pages with the in-app camera, then open the editor.
  static Future<void> flashScanNew(BuildContext context, WidgetRef ref) async {
    final paths = await captureWithFlash(context, ref);
    if (paths == null || !context.mounted) return;
    await ref.read(draftProvider.notifier).startNew(paths);
    _deleteCaptureDir(paths);
    if (context.mounted) context.push(Routes.editor);
  }

  /// "Import": choose photos or a PDF file, then open the editor.
  static Future<void> importNew(BuildContext context, WidgetRef ref) async {
    final source = await showImportSourceSheet(context);
    if (source == null || !context.mounted) return;
    switch (source) {
      case PageSource.gallery:
        await importFromGallery(context, ref);
      case PageSource.pdf:
        await importPdfNew(context, ref);
      case PageSource.scanner:
      case PageSource.flashCamera:
        break;
    }
  }

  /// "From gallery": pick photos, then open the editor.
  static Future<void> importFromGallery(BuildContext context, WidgetRef ref) async {
    final paths = await pickImages(context, ref);
    if (paths == null || !context.mounted) return;
    await ref.read(draftProvider.notifier).startNew(paths);
    if (context.mounted) context.push(Routes.editor);
  }

  /// "PDF file": pick a PDF, render its pages, then open the editor.
  static Future<void> importPdfNew(BuildContext context, WidgetRef ref) async {
    final path = await pickPdf(context);
    if (path == null || !context.mounted) return;
    final paths = await renderPdfs(context, ref, [path]);
    if (paths == null || !context.mounted) return;
    await ref.read(draftProvider.notifier).startNew(paths, filter: PageFilter.original);
    _deleteCaptureDir(paths);
    if (context.mounted) context.push(Routes.editor);
  }

  /// Bottom sheet: photos from the gallery or a PDF file.
  static Future<PageSource?> showImportSourceSheet(BuildContext context) {
    final l10n = context.l10n;
    return showModalBottomSheet<PageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.importFromGallery),
              onTap: () => Navigator.pop(context, PageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.importPdf),
              subtitle: Text(l10n.importPdfHint),
              onTap: () => Navigator.pop(context, PageSource.pdf),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Files shared to the app by another app (WhatsApp, Gmail, Files…):
  /// images become pages as they are, PDFs are rendered. When a document
  /// is already being edited the user chooses between adding the pages to
  /// it and starting a new one. Opens the editor.
  static Future<void> importReceived(BuildContext context, WidgetRef ref, List<String> files) async {
    final l10n = context.l10n;
    final images = [for (final f in files) if (f.isImageFile) f];
    final pdfs = [for (final f in files) if (f.isPdfFile) f];
    if (images.isEmpty && pdfs.isEmpty) {
      showSnack(context, l10n.receivedUnsupported);
      _deleteReceived(files);
      return;
    }
    final pages = [...images];
    if (pdfs.isNotEmpty) {
      final rendered = await renderPdfs(context, ref, pdfs);
      if (rendered != null) pages.addAll(rendered);
    }
    if (!context.mounted || pages.isEmpty) {
      _deleteReceived(files);
      return;
    }

    final draft = ref.read(draftProvider);
    var addToCurrent = false;
    if (draft != null && draft.pages.isNotEmpty) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.file_download_outlined, size: 40),
          title: Text(l10n.receivedTitle),
          content: Text(l10n.receivedAddOrNewBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.receivedNewDocument)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.receivedAddToCurrent)),
          ],
        ),
      );
      if (choice == null || !context.mounted) {
        _deleteReceived(files);
        return;
      }
      addToCurrent = choice;
    }
    final notifier = ref.read(draftProvider.notifier);
    if (addToCurrent) {
      await notifier.addPages(pages, filter: PageFilter.original);
    } else {
      await notifier.startNew(pages, filter: PageFilter.original);
    }
    _deleteReceived(files);
    for (final page in pages) {
      if (!files.contains(page)) _deleteCaptureDir([page]);
    }
    if (!context.mounted) return;
    // Whatever screen was open, show the editor on top of Home.
    final router = GoRouter.of(context);
    router.go(Routes.home);
    router.push(Routes.editor);
  }

  /// Opens the system file picker for one PDF. Returns null when cancelled.
  static Future<String?> pickPdf(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf']);
      final path = picked.isEmpty ? null : picked.first.path;
      return path;
    } catch (_) {
      if (context.mounted) showSnack(context, l10n.importFailed);
      return null;
    }
  }

  /// Renders the pages of [pdfPaths] behind a progress dialog. The JPEGs
  /// land in a folder of their own (see [_deleteCaptureDir]). Returns null
  /// when nothing could be rendered (the user has been told why).
  static Future<List<String>?> renderPdfs(BuildContext context, WidgetRef ref, List<String> pdfPaths) async {
    final l10n = context.l10n;
    try {
      final paths = await ref.read(appPathsProvider.future);
      final service = ref.read(pdfImportServiceProvider);
      if (!context.mounted) return null;
      final pages = await runWithProgressDialog<List<String>>(
        context,
        message: l10n.importingPdf,
        progressText: l10n.importingPdfProgress,
        task: (report) async {
          final out = <String>[];
          for (var i = 0; i < pdfPaths.length; i++) {
            final dir = Directory(p.join(paths.workDir.path, 'pdf_${DateTime.now().microsecondsSinceEpoch}_$i'));
            out.addAll(await service.renderPages(pdfPaths[i], dir, onProgress: report));
          }
          return out;
        },
      );
      if (context.mounted) {
        final truncated = await _anyTruncated(service, pdfPaths);
        if (truncated && context.mounted) showSnack(context, l10n.pdfTooManyPages(PdfImportService.maxPages));
      }
      return pages.isEmpty ? null : pages;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return null;
    }
  }

  static Future<bool> _anyTruncated(PdfImportService service, List<String> pdfPaths) async {
    for (final path in pdfPaths) {
      try {
        if (await service.pageCount(path) > PdfImportService.maxPages) return true;
      } catch (_) {}
    }
    return false;
  }

  /// Removes files another app handed us (each lives in its own temp folder).
  static void _deleteReceived(List<String> files) {
    for (final f in files) {
      File(f).parent.delete(recursive: true).ignore();
    }
  }

  /// Adds pages to the open draft (from the editor).
  static Future<void> addPages(BuildContext context, WidgetRef ref, {required PageSource source}) async {
    final paths = await switch (source) {
      PageSource.scanner => scanPages(context, ref),
      PageSource.flashCamera => captureWithFlash(context, ref),
      PageSource.gallery => pickImages(context, ref),
      PageSource.pdf => _pickAndRenderPdf(context, ref),
    };
    if (paths == null) return;
    await ref
        .read(draftProvider.notifier)
        .addPages(paths, filter: source == PageSource.pdf ? PageFilter.original : DraftController.newPageFilter);
    switch (source) {
      case PageSource.scanner:
        await ref.read(scannerServiceProvider).cleanCache();
      case PageSource.flashCamera:
      case PageSource.pdf:
        _deleteCaptureDir(paths);
      case PageSource.gallery:
    }
  }

  static Future<List<String>?> _pickAndRenderPdf(BuildContext context, WidgetRef ref) async {
    final path = await pickPdf(context);
    if (path == null || !context.mounted) return null;
    return renderPdfs(context, ref, [path]);
  }

  /// Runs the native scanner. Returns null when cancelled or failed (the
  /// user has already been told why).
  static Future<List<String>?> scanPages(BuildContext context, WidgetRef ref, {int maxPages = 50}) async {
    final l10n = context.l10n;
    if (!await PermissionService.ensureCamera(context)) return null;
    try {
      final paths = await ref.read(scannerServiceProvider).scan(maxPages: maxPages);
      if (paths == null || paths.isEmpty) {
        if (context.mounted) showSnack(context, l10n.scanCancelled);
        return null;
      }
      return paths;
    } on ScannerPermissionDenied {
      if (context.mounted) await PermissionService.showPermissionDeniedDialog(context);
    } on PlatformException catch (_) {
      if (context.mounted) showSnack(context, l10n.scanFailed);
    } catch (_) {
      if (context.mounted) showSnack(context, l10n.scanFailed);
    }
    return null;
  }

  /// Opens the in-app camera, whose flash fires only when a photo is taken.
  /// Returns the pages (in a folder of their own, see [_deleteCaptureDir]),
  /// or null when cancelled.
  static Future<List<String>?> captureWithFlash(BuildContext context, WidgetRef ref) async {
    if (!await PermissionService.ensureCamera(context)) return null;
    final Directory dir;
    try {
      final paths = await ref.read(appPathsProvider.future);
      dir = Directory(p.join(paths.workDir.path, 'camera_${DateTime.now().microsecondsSinceEpoch}'));
      await dir.create(recursive: true);
    } catch (e) {
      if (context.mounted) showError(context, e);
      return null;
    }
    if (!context.mounted) return null;
    final pages = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(fullscreenDialog: true, builder: (context) => FlashCameraScreen(outputDir: dir)),
    );
    if (pages == null || pages.isEmpty) {
      dir.delete(recursive: true).ignore();
      return null;
    }
    return pages;
  }

  /// Removes the folder [captureWithFlash] wrote its pages to, once they
  /// have been copied into the draft.
  static void _deleteCaptureDir(List<String> paths) => File(paths.first).parent.delete(recursive: true).ignore();

  /// Opens the gallery picker. Returns null when cancelled or failed.
  static Future<List<String>?> pickImages(BuildContext context, WidgetRef ref, {bool single = false}) async {
    final l10n = context.l10n;
    try {
      final paths = await ref.read(scannerServiceProvider).pickImages(limit: single ? 1 : null);
      return paths.isEmpty ? null : paths;
    } on PlatformException catch (e) {
      if (!context.mounted) return null;
      if (e.code.contains('denied')) {
        await PermissionService.showPermissionDeniedDialog(context);
      } else {
        showSnack(context, l10n.importFailed);
      }
    } catch (_) {
      if (context.mounted) showSnack(context, l10n.importFailed);
    }
    return null;
  }
}
