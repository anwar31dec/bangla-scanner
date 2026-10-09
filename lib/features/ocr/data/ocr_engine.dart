import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/models/enums.dart';
import '../../../core/storage/storage_providers.dart';
import 'ocr_result.dart';
import 'tessdata_installer.dart';

/// Recognizes text in one (already pre-processed) image file, returning the
/// text and the box of every word in pixels of that image.
abstract class OcrEngine {
  Future<RecognizedPage> recognize(String imagePath, OcrLanguage language);
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
  Future<RecognizedPage> recognize(String imagePath, OcrLanguage language) async {
    if (language == OcrLanguage.english) {
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
        return RecognizedPage(
          text: result.text,
          words: [
            for (final block in result.blocks)
              for (final line in block.lines)
                for (final element in line.elements)
                  OcrWord(
                    element.text,
                    left: element.boundingBox.left,
                    top: element.boundingBox.top,
                    right: element.boundingBox.right,
                    bottom: element.boundingBox.bottom,
                  ),
          ],
        );
      } finally {
        await recognizer.close();
      }
    }

    final lang = tesseractLanguage(language);
    // flutter_tesseract_ocr checks every model listed in
    // assets/tessdata_config.json, so install both even for "ben" only.
    await _installer.ensure('ben+eng');
    // hOCR carries the text and the word boxes in one recognition pass.
    final hocr = await FlutterTesseractOcr.extractHocr(
      imagePath,
      language: lang,
      args: {
        // 3 = fully automatic page segmentation without orientation
        // detection (we don't ship osd.traineddata).
        'psm': '3',
        'preserve_interword_spaces': '1',
      },
    );
    return HocrParser.parse(hocr);
  }
}

final ocrEngineProvider = FutureProvider<OcrEngine>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return DefaultOcrEngine(TessdataInstaller(rootBundle.load, paths.tessdataDir));
});
