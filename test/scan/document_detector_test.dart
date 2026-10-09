import 'dart:typed_data';

import 'package:banglascanner/features/scan/data/document_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

typedef _Pt = ({double x, double y});

bool _inside(List<_Pt> quad, double x, double y) {
  for (var i = 0; i < 4; i++) {
    final a = quad[i], b = quad[(i + 1) % 4];
    if ((b.x - a.x) * (y - a.y) - (b.y - a.y) * (x - a.x) < 0) return false;
  }
  return true;
}

/// A photo of a light page (corners [quad], clockwise from top left, in
/// pixels) with dark text lines, lying on a dark table.
img.Image _photo(int width, int height, List<_Pt> quad, {int paper = 225, int table = 45}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var v = table + (x * 20 ~/ width); // uneven light
      if (_inside(quad, x.toDouble(), y.toDouble())) {
        final isText = y % 14 < 3 && x % 50 > 8;
        v = isText ? 60 : paper - (y * 25 ~/ height);
      }
      image.setPixelRgb(x, y, v, v, v);
    }
  }
  return image;
}

Uint8List _rgba(img.Image image) => image.convert(numChannels: 4).getBytes(order: img.ChannelOrder.rgba);

void main() {
  group('DocumentDetector.detect', () {
    test('finds the corners of a tilted page', () {
      const w = 300, h = 400;
      final quad = <_Pt>[(x: 62, y: 48), (x: 251, y: 70), (x: 238, y: 345), (x: 40, y: 322)];
      final found = DocumentDetector.detect(_rgba(_photo(w, h, quad)), w, h);

      expect(found, isNotNull);
      final corners = found!.corners;
      for (var i = 0; i < 4; i++) {
        expect(corners[i].x * w, closeTo(quad[i].x, 5), reason: 'corner $i x');
        expect(corners[i].y * h, closeTo(quad[i].y, 5), reason: 'corner $i y');
      }
      expect(found.isConvex, isTrue);
    });

    test('keeps the shadowed half of a page', () {
      const w = 300, h = 400;
      final quad = <_Pt>[(x: 50, y: 40), (x: 260, y: 40), (x: 260, y: 360), (x: 50, y: 360)];
      final image = _photo(w, h, quad);
      // A hard shadow over the lower half of the page.
      for (var y = 200; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final v = image.getPixel(x, y).r.toInt();
          if (v > 150) image.setPixelRgb(x, y, 105, 105, 105);
        }
      }
      final found = DocumentDetector.detect(_rgba(image), w, h);

      expect(found, isNotNull);
      expect(found!.bottomLeft.y * h, closeTo(360, 6));
      expect(found.bottomRight.y * h, closeTo(360, 6));
    });

    test('finds a page that runs off the edge of the photo', () {
      const w = 320, h = 240;
      final quad = <_Pt>[(x: -20, y: 30), (x: 300, y: 20), (x: 310, y: 215), (x: -20, y: 225)];
      final found = DocumentDetector.detect(_rgba(_photo(w, h, quad)), w, h);

      expect(found, isNotNull);
      expect(found!.topLeft.x, lessThan(0.02));
      expect(found.topRight.x, greaterThan(0.9));
    });

    test('returns null when there is no page', () {
      const w = 300, h = 400;
      final flat = img.Image(width: w, height: h)..clear(img.ColorRgb8(120, 118, 115));
      expect(DocumentDetector.detect(_rgba(flat), w, h), isNull);

      // A small bright spot (lamp reflection) is not a page.
      final spot = <_Pt>[(x: 100, y: 100), (x: 140, y: 100), (x: 140, y: 150), (x: 100, y: 150)];
      expect(DocumentDetector.detect(_rgba(_photo(w, h, spot)), w, h), isNull);
    });

    test('returns null for a bright shape that is not four-sided', () {
      const w = 300, h = 300;
      final image = img.Image(width: w, height: h)..clear(img.ColorRgb8(30, 30, 30));
      img.fillCircle(image, x: 150, y: 150, radius: 110, color: img.ColorRgb8(230, 230, 230));
      expect(DocumentDetector.detect(_rgba(image), w, h), isNull);
    });
  });

  group('DocumentDetector.rectify', () {
    test('flattens the page to its own size without the table', () {
      const w = 600, h = 800;
      final quad = <_Pt>[(x: 120, y: 100), (x: 500, y: 140), (x: 480, y: 690), (x: 80, y: 650)];
      final jpeg = img.encodeJpg(_photo(w, h, quad), quality: 95);
      final page = img.decodeJpg(
        DocumentDetector.rectify(
          jpeg,
          DocumentQuad(
            topLeft: (x: quad[0].x / w, y: quad[0].y / h),
            topRight: (x: quad[1].x / w, y: quad[1].y / h),
            bottomRight: (x: quad[2].x / w, y: quad[2].y / h),
            bottomLeft: (x: quad[3].x / w, y: quad[3].y / h),
          ),
        ),
      )!;

      expect(page.width, closeTo(402, 4)); // longer of the top and bottom edges
      expect(page.height, closeTo(552, 4));
      // No dark table left along the borders (text lines are 60, table ≤ 65).
      for (final (x, y) in [(6, 6), (page.width - 7, 6), (6, page.height - 7), (page.width - 7, page.height - 7)]) {
        // Corners may hit a text line; the paper next to it must be bright.
        final bright = [0, 4, 8].any((dy) => page.getPixel(x, (y + dy).clamp(0, page.height - 1)).r > 150);
        expect(bright, isTrue, reason: 'corner ($x, $y)');
      }
    });

    test('keeps straight lines straight under perspective', () {
      // A trapezoid (page seen from below): its diagonals must cross in the
      // centre of the flattened page.
      const w = 400, h = 400;
      final quad = <_Pt>[(x: 120, y: 60), (x: 280, y: 60), (x: 380, y: 360), (x: 20, y: 360)];
      final image = img.Image(width: w, height: h)..clear(img.ColorRgb8(240, 240, 240));
      img.drawLine(image, x1: 120, y1: 60, x2: 380, y2: 360, color: img.ColorRgb8(0, 0, 0), thickness: 5);
      img.drawLine(image, x1: 280, y1: 60, x2: 20, y2: 360, color: img.ColorRgb8(0, 0, 0), thickness: 5);
      final page = img.decodeJpg(
        DocumentDetector.rectify(
          img.encodeJpg(image, quality: 95),
          DocumentQuad(
            topLeft: (x: quad[0].x / w, y: quad[0].y / h),
            topRight: (x: quad[1].x / w, y: quad[1].y / h),
            bottomRight: (x: quad[2].x / w, y: quad[2].y / h),
            bottomLeft: (x: quad[3].x / w, y: quad[3].y / h),
          ),
        ),
      )!;

      expect(page.getPixel(page.width ~/ 2, page.height ~/ 2).r, lessThan(90));
      expect(page.getPixel(page.width ~/ 2, page.height ~/ 4).r, greaterThan(200));
    });

    test('returns the whole photo for the full quad', () {
      final jpeg = img.encodeJpg(img.Image(width: 120, height: 80)..clear(img.ColorRgb8(200, 200, 200)));
      final page = img.decodeJpg(DocumentDetector.rectify(jpeg, DocumentQuad.full))!;
      expect((page.width, page.height), (120, 80));
    });
  });

  test('DocumentQuad.rotated turns the outline with the photo', () {
    const quad = DocumentQuad(
      topLeft: (x: 0.1, y: 0.2),
      topRight: (x: 0.9, y: 0.2),
      bottomRight: (x: 0.9, y: 0.7),
      bottomLeft: (x: 0.1, y: 0.7),
    );
    // A quarter turn clockwise: the old left edge becomes the top edge.
    void expectPoint(({double x, double y}) actual, double x, double y) {
      expect(actual.x, closeTo(x, 1e-9));
      expect(actual.y, closeTo(y, 1e-9));
    }

    final turned = quad.rotated(1);
    expectPoint(turned.topLeft, 0.3, 0.1);
    expectPoint(turned.topRight, 0.8, 0.1);
    expectPoint(turned.bottomRight, 0.8, 0.9);
    expectPoint(turned.bottomLeft, 0.3, 0.9);
    expect(turned.isConvex, isTrue);
    expectPoint(quad.rotated(2).topLeft, 0.1, 0.3);
    expectPoint(quad.rotated(3).topLeft, 0.2, 0.1);
    expect(quad.rotated(4).topLeft, quad.topLeft);
    expect(quad.rotated(1).rotated(3).maxCornerShift(quad), lessThan(1e-9));
  });

  test('DocumentQuad.isConvex rejects folded and dented outlines', () {
    expect(DocumentQuad.full.isConvex, isTrue);
    expect(DocumentQuad.inset.isConvex, isTrue);
    // Top-left corner dragged past the opposite corner.
    expect(DocumentQuad.inset.withCorner(0, (x: 0.95, y: 0.95)).isConvex, isFalse);
    // Top-right corner pushed into the middle.
    expect(DocumentQuad.inset.withCorner(1, (x: 0.4, y: 0.6)).isConvex, isFalse);
  });
}
