import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Thrown when the camera permission was refused inside the native scanner.
class ScannerPermissionDenied implements Exception {
  const ScannerPermissionDenied();
}

/// Wraps the native document scanner (ML Kit on Android, VisionKit on iOS)
/// and the gallery picker.
class ScannerService {
  final _picker = ImagePicker();

  /// Opens the native scanner with automatic edge detection, cropping and
  /// multi-page capture. Returns image paths, or null if the user cancelled.
  Future<List<String>?> scan({int maxPages = 50}) async {
    try {
      return await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        androidScannerMode: AndroidScannerMode.base,
      );
    } on CunningDocumentScannerException catch (e) {
      if (e.code == 'permission_denied') throw const ScannerPermissionDenied();
      rethrow;
    }
  }

  /// Lets the user pick one or more photos. Returns an empty list when
  /// cancelled.
  Future<List<String>> pickImages({int? limit}) async {
    if (limit == 1) {
      final file = await _picker.pickImage(source: ImageSource.gallery, requestFullMetadata: false);
      return file == null ? const [] : [file.path];
    }
    final files = await _picker.pickMultiImage(limit: limit, requestFullMetadata: false);
    return files.map((f) => f.path).toList();
  }

  /// Removes the scanner plugin's temporary files after we copied them.
  Future<void> cleanCache() async {
    try {
      await CunningDocumentScanner.cleanCache();
    } catch (_) {
      // Best effort only.
    }
  }
}

final scannerServiceProvider = Provider<ScannerService>((ref) => ScannerService());
