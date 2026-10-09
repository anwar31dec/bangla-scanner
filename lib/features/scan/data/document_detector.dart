import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../export/data/image_processing.dart';

/// A position inside a photo as fractions of its width and height (0..1).
typedef QuadPoint = ({double x, double y});

/// The four corners of a page inside a photo.
class DocumentQuad {
  const DocumentQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  /// The whole photo.
  static const full = DocumentQuad(
    topLeft: (x: 0, y: 0),
    topRight: (x: 1, y: 0),
    bottomRight: (x: 1, y: 1),
    bottomLeft: (x: 0, y: 1),
  );

  /// Starting point when no page was found: the photo with a small margin.
  static const inset = DocumentQuad(
    topLeft: (x: 0.08, y: 0.08),
    topRight: (x: 0.92, y: 0.08),
    bottomRight: (x: 0.92, y: 0.92),
    bottomLeft: (x: 0.08, y: 0.92),
  );

  final QuadPoint topLeft;
  final QuadPoint topRight;
  final QuadPoint bottomRight;
  final QuadPoint bottomLeft;

  /// Clockwise from the top left.
  List<QuadPoint> get corners => [topLeft, topRight, bottomRight, bottomLeft];

  /// Copy with the corner at [index] (in [corners] order) moved to [point].
  DocumentQuad withCorner(int index, QuadPoint point) {
    final c = corners..[index] = point;
    return DocumentQuad(topLeft: c[0], topRight: c[1], bottomRight: c[2], bottomLeft: c[3]);
  }

  /// False when the outline folds over itself or a corner points inwards;
  /// such a shape cannot be flattened into a page.
  bool get isConvex {
    final c = corners;
    for (var i = 0; i < 4; i++) {
      final a = c[i], b = c[(i + 1) % 4], d = c[(i + 2) % 4];
      final cross = (b.x - a.x) * (d.y - b.y) - (b.y - a.y) * (d.x - b.x);
      if (cross <= 1e-4) return false;
    }
    return true;
  }

  /// The same outline after the photo is turned clockwise by
  /// [quarterTurns] (used to map camera frames onto the rotated preview).
  DocumentQuad rotated(int quarterTurns) {
    final turns = quarterTurns % 4;
    if (turns == 0) return this;
    final pts = [
      for (final c in corners)
        switch (turns) {
          1 => (x: 1 - c.y, y: c.x),
          2 => (x: 1 - c.x, y: 1 - c.y),
          _ => (x: c.y, y: 1 - c.x),
        },
    ];
    // Corner roles move with the rotation: start again from the top left.
    final start = turns == 1 ? 3 : (turns == 2 ? 2 : 1);
    return DocumentQuad(
      topLeft: pts[start],
      topRight: pts[(start + 1) % 4],
      bottomRight: pts[(start + 2) % 4],
      bottomLeft: pts[(start + 3) % 4],
    );
  }

  /// Largest distance any corner moved between this outline and [other].
  double maxCornerShift(DocumentQuad other) {
    var worst = 0.0;
    final a = corners, b = other.corners;
    for (var i = 0; i < 4; i++) {
      final dx = a[i].x - b[i].x, dy = a[i].y - b[i].y;
      worst = math.max(worst, math.sqrt(dx * dx + dy * dy));
    }
    return worst;
  }

  bool get isFullPhoto {
    const eps = 0.004;
    final c = corners, f = full.corners;
    for (var i = 0; i < 4; i++) {
      if ((c[i].x - f[i].x).abs() > eps || (c[i].y - f[i].y).abs() > eps) return false;
    }
    return true;
  }
}

/// Finds the page in a photo and flattens it. Pure Dart (no Flutter, no
/// I/O) so it can run inside background isolates and be unit tested.
///
/// Detection assumes a page that is brighter than what it lies on, which is
/// the usual case and always true for a flash photo of paper on a table.
class DocumentDetector {
  DocumentDetector._();

  /// Smaller pages are more likely a bright spot than the document.
  static const _minAreaFraction = 0.10;

  /// Paper and background must differ by at least this much (0..255).
  static const _minContrast = 28;

  static const _maxHullPoints = 24;

  /// Runs [detect] in a background isolate.
  static Future<DocumentQuad?> detectInBackground(Uint8List rgba, int width, int height) =>
      Isolate.run(() => detect(rgba, width, height));

  /// Runs [rectify] in a background isolate.
  static Future<Uint8List> rectifyInBackground(Uint8List bytes, DocumentQuad quad) =>
      Isolate.run(() => rectify(bytes, quad));

  /// Looks for the page in a small RGBA copy of the photo (about 300 px is
  /// plenty). Returns null when nothing page-like stands out.
  static DocumentQuad? detect(Uint8List rgba, int width, int height) {
    final n = width * height;
    if (rgba.length < n * 4) return null;
    final luma = Uint8List(n);
    for (var i = 0, j = 0; i < n; i++, j += 4) {
      luma[i] = (0.299 * rgba[j] + 0.587 * rgba[j + 1] + 0.114 * rgba[j + 2]).round();
    }
    return detectLuma(luma, width, height);
  }

  /// [detect] on a brightness-only image (e.g. the Y plane of a camera
  /// frame).
  static DocumentQuad? detectLuma(Uint8List luma, int width, int height) {
    final n = width * height;
    if (width < 16 || height < 16 || luma.length < n) return null;

    luma = _blur(luma, width, height);
    final split = _otsuThreshold(luma);
    if (split == null) return null;

    // Shadowed parts of the page fall below the split; let the page grow
    // into them as long as they are clearly brighter than the background.
    final weak = split - (split - _darkMean(luma, split)) ~/ 2;
    final component = _largestBrightComponent(luma, width, height, strong: split, weak: weak);
    if (component == null || component.area < n * _minAreaFraction) return null;

    final hull = _convexHull(_outline(component.mask, width, height));
    if (hull.length < 4) return null;
    final hullArea = _polygonArea(hull);
    final quad = _largestQuad(_simplify(hull, _maxHullPoints));
    if (quad == null) return null;
    final quadArea = _polygonArea(quad);

    // A page is a filled four-sided shape: the bright region must fill its
    // quad, and the quad must cover nearly all of the region's hull.
    if (quadArea < n * _minAreaFraction) return null;
    if (component.area < quadArea * 0.75 || quadArea < hullArea * 0.82) return null;

    final ordered = _clockwiseFromTopLeft(quad);
    QuadPoint norm(_P p) => (x: _clamp((p.x + 0.5) / width, 0, 1), y: _clamp((p.y + 0.5) / height, 0, 1));
    final result = DocumentQuad(
      topLeft: norm(ordered[0]),
      topRight: norm(ordered[1]),
      bottomRight: norm(ordered[2]),
      bottomLeft: norm(ordered[3]),
    );
    return result.isConvex ? result : null;
  }

  /// Cuts [quad] out of the photo and straightens it into an upright page
  /// (perspective correction). Returns a JPEG.
  static Uint8List rectify(Uint8List bytes, DocumentQuad quad, {int jpegQuality = 92}) {
    final src = ImageProcessing.decode(bytes);
    if (quad.isFullPhoto || !quad.isConvex) return img.encodeJpg(src, quality: jpegQuality);

    final sw = src.width, sh = src.height;
    final maxX = sw - 1.0, maxY = sh - 1.0;
    final c = [for (final p in quad.corners) _P(_clamp(p.x * sw - 0.5, 0, maxX), _clamp(p.y * sh - 0.5, 0, maxY))];
    final tl = c[0], tr = c[1], br = c[2], bl = c[3];
    final dw = math.max(16, math.max(_dist(tl, tr), _dist(bl, br)).round());
    final dh = math.max(16, math.max(_dist(tl, bl), _dist(tr, br)).round());

    // Projective map from the unit square to the quad (Heckbert, 1989).
    final dx1 = tr.x - br.x, dx2 = bl.x - br.x, sx = tl.x - tr.x + br.x - bl.x;
    final dy1 = tr.y - br.y, dy2 = bl.y - br.y, sy = tl.y - tr.y + br.y - bl.y;
    final den = dx1 * dy2 - dx2 * dy1;
    if (den.abs() < 1e-9) return img.encodeJpg(src, quality: jpegQuality);
    final g = (sx * dy2 - dx2 * sy) / den;
    final h = (dx1 * sy - sx * dy1) / den;
    final a = tr.x - tl.x + g * tr.x, b = bl.x - tl.x + h * bl.x;
    final d = tr.y - tl.y + g * tr.y, e = bl.y - tl.y + h * bl.y;

    final from = src.getBytes(order: img.ChannelOrder.rgb);
    final fromStride = sw * 3;
    final to = Uint8List(dw * dh * 3);
    var o = 0;
    for (var y = 0; y < dh; y++) {
      final v = (y + 0.5) / dh;
      for (var x = 0; x < dw; x++) {
        final u = (x + 0.5) / dw;
        final w = g * u + h * v + 1;
        final fx = _clamp((a * u + b * v + tl.x) / w, 0, maxX);
        final fy = _clamp((d * u + e * v + tl.y) / w, 0, maxY);
        // Bilinear sample.
        final x0 = fx.floor(), y0 = fy.floor();
        final x1 = x0 + 1 < sw ? x0 + 1 : x0, y1 = y0 + 1 < sh ? y0 + 1 : y0;
        final tx = fx - x0, ty = fy - y0;
        final w00 = (1 - tx) * (1 - ty), w10 = tx * (1 - ty), w01 = (1 - tx) * ty, w11 = tx * ty;
        final i00 = y0 * fromStride + x0 * 3, i10 = y0 * fromStride + x1 * 3;
        final i01 = y1 * fromStride + x0 * 3, i11 = y1 * fromStride + x1 * 3;
        for (var ch = 0; ch < 3; ch++) {
          to[o++] =
              (from[i00 + ch] * w00 + from[i10 + ch] * w10 + from[i01 + ch] * w01 + from[i11 + ch] * w11).round();
        }
      }
    }
    final page = img.Image.fromBytes(width: dw, height: dh, bytes: to.buffer, numChannels: 3);
    return img.encodeJpg(page, quality: jpegQuality);
  }

  /// 3×3 box blur so print and paper grain do not punch holes into the page.
  static Uint8List _blur(Uint8List luma, int width, int height) {
    final out = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      final ya = y > 0 ? y - 1 : y, yb = y < height - 1 ? y + 1 : y;
      for (var x = 0; x < width; x++) {
        final xa = x > 0 ? x - 1 : x, xb = x < width - 1 ? x + 1 : x;
        final sum = luma[ya * width + xa] + luma[ya * width + x] + luma[ya * width + xb] +
            luma[y * width + xa] + luma[y * width + x] + luma[y * width + xb] +
            luma[yb * width + xa] + luma[yb * width + x] + luma[yb * width + xb];
        out[y * width + x] = sum ~/ 9;
      }
    }
    return out;
  }

  /// Otsu's threshold between background and paper, or null when the photo
  /// has no two clearly different brightness groups.
  static int? _otsuThreshold(Uint8List luma) {
    final hist = Int32List(256);
    for (final v in luma) {
      hist[v]++;
    }
    final total = luma.length;
    var sumAll = 0.0;
    for (var i = 0; i < 256; i++) {
      sumAll += i * hist[i];
    }
    var best = -1.0, bestT = 0, bestGap = 0.0;
    var countLow = 0, sumLow = 0.0;
    for (var t = 0; t < 255; t++) {
      countLow += hist[t];
      sumLow += t * hist[t];
      final countHigh = total - countLow;
      if (countLow == 0 || countHigh == 0) continue;
      final meanLow = sumLow / countLow, meanHigh = (sumAll - sumLow) / countHigh;
      final between = countLow * countHigh * (meanHigh - meanLow) * (meanHigh - meanLow);
      if (between > best) {
        best = between;
        bestT = t;
        bestGap = meanHigh - meanLow;
      }
    }
    return bestGap < _minContrast ? null : bestT;
  }

  /// Average brightness of the pixels at or below [threshold].
  static int _darkMean(Uint8List luma, int threshold) {
    var sum = 0, count = 0;
    for (final v in luma) {
      if (v <= threshold) {
        sum += v;
        count++;
      }
    }
    return count == 0 ? threshold : sum ~/ count;
  }

  /// The biggest connected group of pixels brighter than [weak] that was
  /// entered from a pixel brighter than [strong] (hysteresis threshold).
  static ({Uint8List mask, int area})? _largestBrightComponent(
    Uint8List luma,
    int width,
    int height, {
    required int strong,
    required int weak,
  }) {
    final n = width * height;
    final labels = Int32List(n); // 0 = unvisited or dark
    final queue = Int32List(n);
    var bestLabel = 0, bestArea = 0, label = 0;
    for (var start = 0; start < n; start++) {
      if (luma[start] <= strong || labels[start] != 0) continue;
      label++;
      var head = 0, tail = 0;
      queue[tail++] = start;
      labels[start] = label;
      while (head < tail) {
        final i = queue[head++];
        final x = i % width;
        void visit(int j) {
          if (luma[j] > weak && labels[j] == 0) {
            labels[j] = label;
            queue[tail++] = j;
          }
        }

        if (x > 0) visit(i - 1);
        if (x < width - 1) visit(i + 1);
        if (i >= width) visit(i - width);
        if (i < n - width) visit(i + width);
      }
      if (tail > bestArea) {
        bestArea = tail;
        bestLabel = label;
      }
    }
    if (bestLabel == 0) return null;
    final mask = Uint8List(n);
    for (var i = 0; i < n; i++) {
      if (labels[i] == bestLabel) mask[i] = 1;
    }
    return (mask: mask, area: bestArea);
  }

  /// First and last pixel of every row: enough to build the convex hull.
  static List<_P> _outline(Uint8List mask, int width, int height) {
    final points = <_P>[];
    for (var y = 0; y < height; y++) {
      final row = y * width;
      var first = -1, last = -1;
      for (var x = 0; x < width; x++) {
        if (mask[row + x] != 0) {
          if (first < 0) first = x;
          last = x;
        }
      }
      if (first < 0) continue;
      points.add(_P(first.toDouble(), y.toDouble()));
      if (last != first) points.add(_P(last.toDouble(), y.toDouble()));
    }
    return points;
  }

  /// Andrew's monotone chain. Returns the hull without repeated end point.
  static List<_P> _convexHull(List<_P> points) {
    if (points.length < 3) return points;
    final sorted = [...points]..sort((a, b) => a.x != b.x ? a.x.compareTo(b.x) : a.y.compareTo(b.y));
    double cross(_P o, _P a, _P b) => (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
    final hull = <_P>[];
    for (final p in sorted) {
      while (hull.length >= 2 && cross(hull[hull.length - 2], hull.last, p) <= 0) {
        hull.removeLast();
      }
      hull.add(p);
    }
    final lowerSize = hull.length + 1;
    for (final p in sorted.reversed.skip(1)) {
      while (hull.length >= lowerSize && cross(hull[hull.length - 2], hull.last, p) <= 0) {
        hull.removeLast();
      }
      hull.add(p);
    }
    return hull..removeLast();
  }

  /// Drops the hull points that matter least (smallest triangle with their
  /// neighbours) until at most [max] remain.
  static List<_P> _simplify(List<_P> hull, int max) {
    final points = [...hull];
    while (points.length > max) {
      var drop = 0;
      var smallest = double.infinity;
      for (var i = 0; i < points.length; i++) {
        final area = _triangleArea(
          points[(i - 1 + points.length) % points.length],
          points[i],
          points[(i + 1) % points.length],
        );
        if (area < smallest) {
          smallest = area;
          drop = i;
        }
      }
      points.removeAt(drop);
    }
    return points;
  }

  /// The four hull points spanning the largest area: the page corners.
  static List<_P>? _largestQuad(List<_P> hull) {
    final n = hull.length;
    if (n < 4) return null;
    List<_P>? best;
    var bestArea = 0.0;
    for (var i = 0; i < n - 3; i++) {
      for (var j = i + 1; j < n - 2; j++) {
        for (var k = j + 1; k < n - 1; k++) {
          for (var l = k + 1; l < n; l++) {
            final quad = [hull[i], hull[j], hull[k], hull[l]];
            final area = _polygonArea(quad);
            if (area > bestArea) {
              bestArea = area;
              best = quad;
            }
          }
        }
      }
    }
    return best;
  }

  /// Orders corners clockwise as seen on screen, starting with the one
  /// nearest the photo's top left.
  static List<_P> _clockwiseFromTopLeft(List<_P> quad) {
    final cx = quad.fold(0.0, (s, p) => s + p.x) / 4, cy = quad.fold(0.0, (s, p) => s + p.y) / 4;
    // With y pointing down, a growing angle walks clockwise on screen.
    final sorted = [...quad]
      ..sort((a, b) => math.atan2(a.y - cy, a.x - cx).compareTo(math.atan2(b.y - cy, b.x - cx)));
    var start = 0;
    for (var i = 1; i < 4; i++) {
      if (sorted[i].x + sorted[i].y < sorted[start].x + sorted[start].y) start = i;
    }
    return [for (var i = 0; i < 4; i++) sorted[(start + i) % 4]];
  }

  static double _polygonArea(List<_P> points) {
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i], b = points[(i + 1) % points.length];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum.abs() / 2;
  }

  static double _triangleArea(_P a, _P b, _P c) =>
      ((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)).abs() / 2;

  static double _clamp(double v, double min, double max) => v < min ? min : (v > max ? max : v);

  static double _dist(_P a, _P b) => math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

class _P {
  const _P(this.x, this.y);

  final double x;
  final double y;
}
