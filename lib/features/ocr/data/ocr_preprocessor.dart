import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../export/data/image_processing.dart';

/// Prepares a page image for OCR. Pure Dart; runs in a background isolate.
///
/// Tesseract is most accurate when text is dark on a clean light
/// background and characters are roughly 20–40 px tall. Steps:
///  1. resize so the long edge is between [minEdge] and [maxEdge]
///     (upscale small photos, downscale huge ones for speed),
///  2. grayscale,
///  3. stretch brightness to the full range (removes grey cast),
///  4. boost contrast.
class OcrPreprocessor {
  OcrPreprocessor._();

  static const minEdge = 1800;
  static const maxEdge = 2600;

  static Uint8List process(Uint8List bytes) {
    var image = ImageProcessing.decode(bytes);

    final longest = math.max(image.width, image.height);
    final target = longest < minEdge ? minEdge : (longest > maxEdge ? maxEdge : longest);
    if (target != longest) {
      final scale = target / longest;
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: scale > 1 ? img.Interpolation.cubic : img.Interpolation.average,
      );
    }

    image = img.grayscale(image);
    image = ImageProcessing.autoLevels(image);
    image = img.contrast(image, contrast: 135);

    // PNG keeps text edges sharp (no JPEG artefacts). Level 1 = fast.
    return img.encodePng(image, level: 1);
  }
}
