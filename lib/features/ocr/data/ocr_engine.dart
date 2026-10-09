import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/models/enums.dart';
import '../../../core/storage/storage_providers.dart';
import 'tessdata_installer.dart';

/// Recognizes text in one (already pre-processed) image file.
abstract class OcrEngine {
  Future<String> recognize(String imagePath, OcrLanguage language);
}

/// Offline OCR:
/// * বাংলা → Tesseract `ben`
/// * English → Google ML Kit (Latin, bundled model)
/// * Both → Tesseract `ben+eng`
///
/// Both engines run natively on a background thread, so the Flutter UI
/// thread is never blocked while text is recognized.
class DefaultOcrEngine implements OcrEngine {
  DefaultOcrEngine(this._installer);

  final TessdataInstaller _installer;

  static String tesseractLanguage(OcrLanguage language) => language == OcrLanguage.both ? 'ben+eng' : 'ben';

  @override
  Future<String> recognize(String imagePath, OcrLanguage language) async {
    if (language == OcrLanguage.english) {
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
        return result.text;
      } finally {
        await recognizer.close();
      }
    }

    final lang = tesseractLanguage(language);
    // flutter_tesseract_ocr checks every model listed in
    // assets/tessdata_config.json, so install both even for "ben" only.
    await _installer.ensure('ben+eng');
    return FlutterTesseractOcr.extractText(
      imagePath,
      language: lang,
      args: {
        // 3 = fully automatic page segmentation without orientation
        // detection (we don't ship osd.traineddata).
        'psm': '3',
        'preserve_interword_spaces': '1',
      },
    );
  }
}

final ocrEngineProvider = FutureProvider<OcrEngine>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return DefaultOcrEngine(TessdataInstaller(rootBundle.load, paths.tessdataDir));
});
