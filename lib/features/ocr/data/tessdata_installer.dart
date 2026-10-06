import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Loads an asset by key (normally `rootBundle.load`).
typedef AssetLoader = Future<ByteData> Function(String key);

/// Installs the bundled Tesseract language models.
///
/// To keep the app small the models ship gzip-compressed
/// (`assets/tessdata/*.traineddata.gz`, roughly half the size). On first OCR
/// use they are decompressed once into `<app documents>/tessdata/`, which is
/// where flutter_tesseract_ocr reads them from.
class TessdataInstaller {
  TessdataInstaller(this._load, this._tessdataDir);

  final AssetLoader _load;
  final Directory _tessdataDir;

  static const assetFolder = 'assets/tessdata';

  /// Makes sure every model needed for [tesseractLanguage] (e.g. "ben+eng")
  /// is installed.
  Future<void> ensure(String tesseractLanguage) async {
    await _tessdataDir.create(recursive: true);
    for (final lang in tesseractLanguage.split('+')) {
      final target = File(p.join(_tessdataDir.path, '$lang.traineddata'));
      if (await target.exists() && await target.length() > 0) continue;

      final data = await _load('$assetFolder/$lang.traineddata.gz');
      final compressed = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final bytes = await Isolate.run(() => Uint8List.fromList(gzip.decode(compressed)));

      // Write to a temp name and rename, so an interrupted write (app
      // killed, storage full) never leaves a broken model behind.
      final tmp = File('${target.path}.part');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(target.path);
    }
  }
}
