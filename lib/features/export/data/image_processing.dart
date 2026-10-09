import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/models/enums.dart';
import '../../../core/utils/app_exception.dart';
import '../../scan/data/draft_document.dart';

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

  /// Applies one of the document filters, then the manual [adjustments]
  /// (filter strength, brightness, contrast). [src] is never modified.
  static img.Image applyFilter(img.Image src, PageFilter filter, {PageAdjustments adjustments = PageAdjustments.none}) {
    var out = _filterOnly(src, filter);
    if (filter != PageFilter.original && adjustments.strength < 1) out = blend(src, out, adjustments.strength);
    if (adjustments.brightness != 0 || adjustments.contrast != 0) {
      if (identical(out, src)) out = src.clone();
      adjustTone(out, brightness: adjustments.brightness, contrast: adjustments.contrast);
    }
    return out;
  }

  /// Mixes [filtered] over [original]: 0 gives the original, 1 the filtered
  /// image. Both must have the same size and RGB layout.
  static img.Image blend(img.Image original, img.Image filtered, double amount) {
    final t = amount.clamp(0.0, 1.0);
    if (t >= 1) return filtered;
    if (t <= 0) return original.clone();
    if (original.width != filtered.width ||
        original.height != filtered.height ||
        original.numChannels != 3 ||
        filtered.numChannels != 3 ||
        original.format != img.Format.uint8 ||
        filtered.format != img.Format.uint8) {
      return filtered;
    }
    final a = original.toUint8List(), b = filtered.toUint8List();
    final out = img.Image(width: original.width, height: original.height);
    final dst = out.toUint8List();
    // Fixed point: 0..256.
    final k = (t * 256).round();
    for (var i = 0; i < dst.length; i++) {
      dst[i] = a[i] + (((b[i] - a[i]) * k) >> 8);
    }
    return out;
  }

  /// Brightness (-1…1) and contrast (-1…1) through a lookup table, in place.
  static img.Image adjustTone(img.Image image, {double brightness = 0, double contrast = 0}) {
    if (brightness == 0 && contrast == 0) return image;
    final c = contrast.clamp(-1.0, 1.0);
    // Slope 0.25 at -1, 1 at 0, 2.5 at +1.
    final slope = c >= 0 ? 1 + c * 1.5 : 1 + c * 0.75;
    final shift = brightness.clamp(-1.0, 1.0) * 128;
    final lut = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      lut[i] = ((i - 128) * slope + 128 + shift).round().clamp(0, 255);
    }
    if (image.numChannels == 3 && !image.hasPalette && image.format == img.Format.uint8) {
      final px = image.toUint8List();
      for (var i = 0; i < px.length; i++) {
        px[i] = lut[px[i]];
      }
      return image;
    }
    for (final p in image) {
      p
        ..r = lut[p.r.toInt().clamp(0, 255)]
        ..g = lut[p.g.toInt().clamp(0, 255)]
        ..b = lut[p.b.toInt().clamp(0, 255)];
    }
    return image;
  }

  static img.Image _filterOnly(img.Image src, PageFilter filter) {
    switch (filter) {
      case PageFilter.original:
        return src;
      case PageFilter.autoColor:
        return whitenEdges(cleanDocument(src, saturation: 1.15));
      case PageFilter.grayscale:
        return whitenEdges(cleanDocument(src, gray: true));
      case PageFilter.blackWhite:
        return whitenEdges(adaptiveThreshold(src));
      case PageFilter.whiteboard:
        // Boards are grey and glossy: clip harder at both ends and make the
        // marker colours pop.
        return whitenEdges(cleanDocument(src, whitePoint: 0.82, blackPoint: 0.25, saturation: 1.6));
      case PageFilter.lightText:
        // The gamma darkens faint strokes (pencil, weak print) without
        // touching the paper.
        return whitenEdges(cleanDocument(src, gray: true, blackPoint: 0, gamma: 2.2));
    }
  }

  /// Whitens, in place, the thin dark strip a crop leaves along the page
  /// edges (a sliver of table or shadow beside the paper), which the filters
  /// keep as if it were ink.
  ///
  /// Every edge pixel is followed inwards: whatever lies between the edge
  /// and the first stretch of white paper is erased. If no paper turns up
  /// within the strip depth, the pixels are left alone, so a coloured page,
  /// a photo or a ruled line running off the page stay as they are.
  static img.Image whitenEdges(img.Image image) {
    final w = image.width, h = image.height;
    final depth = math.max(w, h) ~/ _edgeStripFraction;
    // White pixels in a row that count as paper; a single one may be noise
    // inside the strip.
    final gap = math.max(2, depth ~/ 4);
    if (depth < 1 || math.min(w, h) <= depth + gap) return image;
    if (image.numChannels != 3 || image.hasPalette || image.format != img.Format.uint8) return image;
    final px = image.toUint8List();

    void side(int length, int Function(int along, int inwards) offset) {
      for (var i = 0; i < length; i++) {
        var white = 0, end = -1;
        for (var d = 0; d < depth + gap; d++) {
          final j = offset(i, d);
          if (px[j] < _paperWhite || px[j + 1] < _paperWhite || px[j + 2] < _paperWhite) {
            white = 0;
          } else if (++white == gap) {
            end = d - gap + 1;
            break;
          }
        }
        for (var d = 0; d < end; d++) {
          final j = offset(i, d);
          px[j] = 255;
          px[j + 1] = 255;
          px[j + 2] = 255;
        }
      }
    }

    side(w, (x, d) => (d * w + x) * 3);
    side(w, (x, d) => ((h - 1 - d) * w + x) * 3);
    side(h, (y, d) => (y * w + d) * 3);
    side(h, (y, d) => (y * w + w - 1 - d) * 3);
    return image;
  }

  /// The edge strip is at most 1/120 of the longest edge deep (2.5 mm on A4);
  /// a slightly crooked crop leaves a wedge that reaches about that far.
  static const _edgeStripFraction = 120;
  static const _paperWhite = 245;

  /// Full page pipeline used when saving: decode → rotate → filter → resize
  /// → JPEG.
  static Uint8List processPage(
    Uint8List bytes, {
    required int quarterTurns,
    required PageFilter filter,
    required ExportQuality quality,
    PageAdjustments adjustments = PageAdjustments.none,
  }) {
    var image = decode(bytes);
    // Resize first: filters are much faster on smaller images.
    image = limitSize(image, quality.maxEdge);
    image = rotateQuarterTurns(image, quarterTurns);
    image = applyFilter(image, filter, adjustments: adjustments);
    return img.encodeJpg(image, quality: quality.jpegQuality);
  }

  /// Book mode: cuts a photo of an open book (two pages side by side) into
  /// two page images, in reading order. A landscape image is split into a
  /// left and a right half; a portrait one into a top and a bottom half.
  /// [quarterTurns] is baked in first so the split follows what the user
  /// sees.
  static (Uint8List, Uint8List) splitSpread(Uint8List bytes, {int quarterTurns = 0}) {
    final image = rotateQuarterTurns(decode(bytes), quarterTurns);
    final w = image.width, h = image.height;
    final img.Image first, second;
    if (w >= h) {
      final half = w ~/ 2;
      first = img.copyCrop(image, x: 0, y: 0, width: half, height: h);
      second = img.copyCrop(image, x: half, y: 0, width: w - half, height: h);
    } else {
      final half = h ~/ 2;
      first = img.copyCrop(image, x: 0, y: 0, width: w, height: half);
      second = img.copyCrop(image, x: 0, y: half, width: w, height: h - half);
    }
    return (img.encodeJpg(first, quality: 95), img.encodeJpg(second, quality: 95));
  }

  /// Bakes a rotation into a high quality JPEG (used before manual crop so
  /// the cropper shows the page the way the user sees it).
  static Uint8List rotateJpeg(Uint8List bytes, int quarterTurns) {
    final image = rotateQuarterTurns(decode(bytes), quarterTurns);
    return img.encodeJpg(image, quality: 95);
  }

  /// Small JPEG used as a list thumbnail.
  static Uint8List thumbnail(Uint8List bytes, {int maxEdge = 360}) {
    final image = limitSize(decode(bytes), maxEdge);
    return img.encodeJpg(image, quality: 70);
  }

  /// Applies [filter] to raw RGBA pixels and returns a JPEG. Used for the
  /// on-screen previews, which decode the page at screen size with the
  /// platform codec (much faster than [decode] on a full camera photo).
  static Uint8List previewJpeg(
    Uint8List rgba,
    int width,
    int height,
    PageFilter filter, {
    PageAdjustments adjustments = PageAdjustments.none,
  }) {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      bytesOffset: rgba.offsetInBytes,
      numChannels: 4,
    ).convert(numChannels: 3);
    return img.encodeJpg(applyFilter(image, filter, adjustments: adjustments), quality: 90);
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

  /// The "scanned" look: evens out the lighting, turns the paper white and
  /// deepens the ink, while keeping colours (or dropping them with [gray]).
  ///
  /// The brightness of the bare paper is estimated on a coarse grid (a high
  /// percentile of each cell ignores the ink), small dark areas are filled
  /// in from their surroundings, and every pixel is then divided by the
  /// paper brightness at its position. That removes shadows and uneven
  /// light. A tone curve finally maps everything above [whitePoint] to
  /// white and everything below [blackPoint] to black.
  static img.Image cleanDocument(
    img.Image src, {
    bool gray = false,
    double whitePoint = 0.9,
    double blackPoint = 0.1,
    double gamma = 1.0,
    double saturation = 1.0,
  }) {
    if (src.numChannels != 3 || src.hasPalette || src.format != img.Format.uint8) {
      src = src.convert(numChannels: 3, format: img.Format.uint8);
    }
    final w = src.width, h = src.height;
    final out = img.Image(width: w, height: h);
    if (w == 0 || h == 0) return out;
    final rgb = src.toUint8List(), dst = out.toUint8List();

    // Brightness used to find the paper. The strongest channel (rather than
    // luma) keeps saturated colours bright, so a coloured banner is not
    // mistaken for a shadow and bleached.
    final value = Uint8List(w * h);
    for (var i = 0, j = 0; i < value.length; i++, j += 3) {
      final r = rgb[j], g = rgb[j + 1], b = rgb[j + 2];
      value[i] = gray ? (r * 77 + g * 150 + b * 29) >> 8 : math.max(r, math.max(g, b));
    }

    // 1. Paper brightness (and colour) per grid cell.
    final cell = math.max(8, math.max(w, h) ~/ _paperGridCells);
    final gw = math.max(1, (w / cell).round()), gh = math.max(1, (h / cell).round());
    var paper = Float32List(gw * gh);
    final paperRgb = Float64List(gw * gh * 3);
    final histogram = Int32List(256);
    for (var gy = 0; gy < gh; gy++) {
      final y0 = gy * h ~/ gh, y1 = (gy + 1) * h ~/ gh;
      for (var gx = 0; gx < gw; gx++) {
        final x0 = gx * w ~/ gw, x1 = (gx + 1) * w ~/ gw;
        histogram.fillRange(0, 256, 0);
        for (var y = y0; y < y1; y++) {
          for (var i = y * w + x0, end = y * w + x1; i < end; i++) {
            histogram[value[i]]++;
          }
        }
        // 85th percentile: brighter than any ink, not fooled by glints.
        final skip = (x1 - x0) * (y1 - y0) * 15 ~/ 100;
        var level = 255, acc = 0;
        for (; level > 0; level--) {
          acc += histogram[level];
          if (acc > skip) break;
        }
        paper[gy * gw + gx] = level.toDouble();
        if (gray) continue;
        var sr = 0, sg = 0, sb = 0, n = 0;
        for (var y = y0; y < y1; y++) {
          for (var i = y * w + x0, end = y * w + x1; i < end; i++) {
            if (value[i] < level) continue;
            sr += rgb[i * 3];
            sg += rgb[i * 3 + 1];
            sb += rgb[i * 3 + 2];
            n++;
          }
        }
        if (n > 0) {
          final o = (gy * gw + gx) * 3;
          paperRgb[o] = sr / n;
          paperRgb[o + 1] = sg / n;
          paperRgb[o + 2] = sb / n;
        }
      }
    }

    // White balance from the brighter half of the cells (the ones that are
    // certainly paper): scale each channel so the paper becomes neutral.
    // Capped so a deliberately coloured page keeps its colour.
    var gainR = 1.0, gainG = 1.0, gainB = 1.0;
    if (!gray) {
      final median = (Float32List.fromList(paper)..sort())[paper.length ~/ 2];
      var r = 0.0, g = 0.0, b = 0.0;
      for (var i = 0; i < paper.length; i++) {
        if (paper[i] < median) continue;
        r += paperRgb[i * 3];
        g += paperRgb[i * 3 + 1];
        b += paperRgb[i * 3 + 2];
      }
      final top = math.max(r, math.max(g, b));
      if (math.min(r, math.min(g, b)) > 0) {
        gainR = math.min(top / r, _maxWhiteBalanceGain);
        gainG = math.min(top / g, _maxWhiteBalanceGain);
        gainB = math.min(top / b, _maxWhiteBalanceGain);
      }
    }

    // 2. Cells covered by a headline or stamp have no bare paper; closing
    // (grow bright, then shrink back) fills them in from the paper around
    // them. A larger radius would leave a halo at shadow edges. A light
    // blur hides the grid.
    paper = _gridFilter(paper, gw, gh, 1, math.max);
    paper = _gridFilter(paper, gw, gh, 1, math.min);
    paper = _gridFilter(paper, gw, gh, 1, null);
    // Limit how far very dark areas (large photos) get brightened.
    final floor = paper.reduce(math.max) * 0.4;
    for (var i = 0; i < paper.length; i++) {
      paper[i] = math.max(1, math.max(floor, paper[i]));
    }

    final tone = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      final t = ((i / 255 - blackPoint) / (whitePoint - blackPoint)).clamp(0.0, 1.0);
      tone[i] = (math.pow(t, gamma) * 255).round();
    }

    // 3. Divide every pixel by the paper brightness at its position
    // (bilinear interpolation between cell centres), then apply the curve.
    final cx0 = Int32List(w), cx1 = Int32List(w);
    final wx = Float32List(w);
    for (var x = 0; x < w; x++) {
      final fx = ((x + 0.5) * gw / w - 0.5).clamp(0.0, gw - 1.0);
      cx0[x] = fx.floor();
      cx1[x] = math.min(cx0[x] + 1, gw - 1);
      wx[x] = fx - cx0[x];
    }
    final row = Float32List(gw);
    for (var y = 0; y < h; y++) {
      final fy = ((y + 0.5) * gh / h - 0.5).clamp(0.0, gh - 1.0);
      final gy0 = fy.floor(), gy1 = math.min(gy0 + 1, gh - 1);
      final wy = fy - gy0;
      for (var gx = 0; gx < gw; gx++) {
        final a = paper[gy0 * gw + gx];
        row[gx] = a + (paper[gy1 * gw + gx] - a) * wy;
      }
      for (var x = 0, i = y * w, j = y * w * 3; x < w; x++, i++, j += 3) {
        final a = row[cx0[x]];
        final k = 255 / (a + (row[cx1[x]] - a) * wx[x]);
        if (gray) {
          final v = tone[math.min(255, (value[i] * k).toInt())];
          dst[j] = v;
          dst[j + 1] = v;
          dst[j + 2] = v;
          continue;
        }
        var r = tone[math.min(255, (rgb[j] * k * gainR).toInt())];
        var g = tone[math.min(255, (rgb[j + 1] * k * gainG).toInt())];
        var b = tone[math.min(255, (rgb[j + 2] * k * gainB).toInt())];
        if (saturation != 1.0) {
          final l = (r * 77 + g * 150 + b * 29) >> 8;
          r = (l + (r - l) * saturation).round().clamp(0, 255);
          g = (l + (g - l) * saturation).round().clamp(0, 255);
          b = (l + (b - l) * saturation).round().clamp(0, 255);
        }
        dst[j] = r;
        dst[j + 1] = g;
        dst[j + 2] = b;
      }
    }
    return out;
  }

  /// Cells along the longest edge of the paper brightness grid. A cell must
  /// be bigger than a line of text and smaller than a shadow.
  static const _paperGridCells = 40;
  static const _maxWhiteBalanceGain = 1.4;

  /// Runs a square window of the given [radius] over a small grid, combining
  /// the values with [pick] (max/min), or averaging them when it is null.
  static Float32List _gridFilter(Float32List grid, int gw, int gh, int radius, double Function(double, double)? pick) {
    final out = Float32List(grid.length);
    for (var y = 0; y < gh; y++) {
      for (var x = 0; x < gw; x++) {
        double? result;
        var sum = 0.0, n = 0;
        for (var yy = math.max(0, y - radius); yy <= math.min(gh - 1, y + radius); yy++) {
          for (var xx = math.max(0, x - radius); xx <= math.min(gw - 1, x + radius); xx++) {
            final v = grid[yy * gw + xx];
            result = result == null || pick == null ? v : pick(result, v);
            sum += v;
            n++;
          }
        }
        out[y * gw + x] = pick == null ? sum / n : result!;
      }
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
    // Three equal channels: the JPEG encoder reads a single-channel image
    // as pure red.
    final out = img.Image(width: w, height: h);
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
        out.setPixelRgb(x, y, value, value, value);
      }
    }
    return out;
  }

  static int _luma(num r, num g, num b) => (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
}
