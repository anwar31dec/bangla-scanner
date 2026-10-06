import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/models/enums.dart';
import '../../../core/utils/app_exception.dart';

/// Pure image operations (no Flutter, no I/O) so they can run inside
/// background isolates and be unit tested.
class ImageProcessing {
  ImageProcessing._();

  /// Decodes [bytes] and applies the EXIF orientation. Throws
  /// [AppErrorKind.corruptFile] when the data is not a readable image.
  static img.Image decode(Uint8List bytes) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null || decoded.width == 0 || decoded.height == 0) {
      throw const AppException(AppErrorKind.corruptFile);
    }
    var image = img.bakeOrientation(decoded);
    // Normalise grey/palette/alpha images to RGB so every filter sees the
    // same channel layout.
    if (image.numChannels != 3 || image.hasPalette || image.format != img.Format.uint8) {
      image = image.convert(numChannels: 3, format: img.Format.uint8);
    }
    return image;
  }

  /// Rotates by a number of clockwise quarter turns.
  static img.Image rotateQuarterTurns(img.Image src, int quarterTurns) {
    final turns = quarterTurns % 4;
    if (turns == 0) return src;
    return img.copyRotate(src, angle: 90 * turns);
  }

  /// Downscales so the longest edge is at most [maxEdge]. Never upscales.
  static img.Image limitSize(img.Image src, int maxEdge) {
    final longest = math.max(src.width, src.height);
    if (longest <= maxEdge) return src;
    final scale = maxEdge / longest;
    return img.copyResize(
      src,
      width: (src.width * scale).round(),
      height: (src.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }

  /// Applies one of the document filters.
  static img.Image applyFilter(img.Image src, PageFilter filter) {
    switch (filter) {
      case PageFilter.original:
        return src;
      case PageFilter.grayscale:
        return img.grayscale(src.clone());
      case PageFilter.blackWhite:
        return adaptiveThreshold(src);
      case PageFilter.enhanced:
        final stretched = autoLevels(src);
        return img.adjustColor(stretched, contrast: 1.12, saturation: 1.1);
    }
  }

  /// Full page pipeline used when saving: decode → rotate → filter → resize
  /// → JPEG.
  static Uint8List processPage(
    Uint8List bytes, {
    required int quarterTurns,
    required PageFilter filter,
    required ExportQuality quality,
  }) {
    var image = decode(bytes);
    // Resize first: filters are much faster on smaller images.
    image = limitSize(image, quality.maxEdge);
    image = rotateQuarterTurns(image, quarterTurns);
    image = applyFilter(image, filter);
    return img.encodeJpg(image, quality: quality.jpegQuality);
  }

  /// Small JPEG used as a list thumbnail.
  static Uint8List thumbnail(Uint8List bytes, {int maxEdge = 360}) {
    final image = limitSize(decode(bytes), maxEdge);
    return img.encodeJpg(image, quality: 70);
  }

  /// Stretches the brightness range so the darkest 1% becomes black and the
  /// brightest 1% white. Removes the grey cast of photos taken in poor light.
  static img.Image autoLevels(img.Image src, {double clip = 0.01}) {
    final out = src.clone();
    final histogram = List<int>.filled(256, 0);
    for (final p in out) {
      histogram[_luma(p.r, p.g, p.b)]++;
    }
    final total = out.width * out.height;
    final clipCount = (total * clip).round();
    var low = 0, high = 255, acc = 0;
    for (var i = 0; i < 256; i++) {
      acc += histogram[i];
      if (acc > clipCount) {
        low = i;
        break;
      }
    }
    acc = 0;
    for (var i = 255; i >= 0; i--) {
      acc += histogram[i];
      if (acc > clipCount) {
        high = i;
        break;
      }
    }
    if (high - low < 10) return out;
    final scale = 255 / (high - low);
    int map(num v) => ((v - low) * scale).round().clamp(0, 255);
    for (final p in out) {
      p
        ..r = map(p.r)
        ..g = map(p.g)
        ..b = map(p.b);
    }
    return out;
  }

  /// High contrast black & white for documents.
  ///
  /// A global threshold fails when part of the page is in shadow, so each
  /// pixel is compared with the mean brightness of its neighbourhood
  /// (Bradley adaptive thresholding, computed with an integral image).
  static img.Image adaptiveThreshold(img.Image src, {double sensitivity = 0.12}) {
    final w = src.width, h = src.height;
    final luma = Uint8List(w * h);
    var i = 0;
    for (final p in src) {
      luma[i++] = _luma(p.r, p.g, p.b);
    }

    // Integral image: sum of all luma values above and left of (x, y).
    final integral = Uint32List((w + 1) * (h + 1));
    for (var y = 0; y < h; y++) {
      var rowSum = 0;
      for (var x = 0; x < w; x++) {
        rowSum += luma[y * w + x];
        integral[(y + 1) * (w + 1) + x + 1] = integral[y * (w + 1) + x + 1] + rowSum;
      }
    }

    final half = math.max(8, math.max(w, h) ~/ 32);
    final out = img.Image(width: w, height: h, numChannels: 1);
    for (var y = 0; y < h; y++) {
      final y0 = math.max(0, y - half), y1 = math.min(h - 1, y + half);
      for (var x = 0; x < w; x++) {
        final x0 = math.max(0, x - half), x1 = math.min(w - 1, x + half);
        final count = (x1 - x0 + 1) * (y1 - y0 + 1);
        final sum = integral[(y1 + 1) * (w + 1) + x1 + 1] -
            integral[y0 * (w + 1) + x1 + 1] -
            integral[(y1 + 1) * (w + 1) + x0] +
            integral[y0 * (w + 1) + x0];
        final value = luma[y * w + x] * count <= sum * (1 - sensitivity) ? 0 : 255;
        out.setPixelR(x, y, value);
      }
    }
    return out;
  }

  static int _luma(num r, num g, num b) => (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
}
