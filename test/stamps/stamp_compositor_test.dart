import 'dart:typed_data';

import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/features/stamps/data/stamp_compositor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  /// A white 400×600 page.
  Uint8List whitePage() {
    final page = img.Image(width: 400, height: 600);
    img.fill(page, color: img.ColorRgb8(255, 255, 255));
    return img.encodeJpg(page, quality: 95);
  }

  /// A solid red 100×50 stamp with a transparent left half.
  Uint8List redStamp() {
    final stamp = img.Image(width: 100, height: 50, numChannels: 4);
    for (final px in stamp) {
      if (px.x >= 50) {
        px
          ..r = 220
          ..g = 0
          ..b = 0
          ..a = 255;
      }
    }
    return img.encodePng(stamp);
  }

  test('draws the stamp at the placement, honouring transparency', () {
    final out = img.decodeJpg(
      StampCompositor.apply(
        whitePage(),
        redStamp(),
        placement: const StampPlacement(centerX: 0.5, centerY: 0.5, widthFraction: 0.5),
      ),
    )!;
    expect(out.width, 400);
    expect(out.height, 600);
    // Stamp is 200×100 centred at (200, 300): right half red, left half untouched.
    final red = out.getPixel(250, 300);
    expect(red.r, greaterThan(180));
    expect(red.g, lessThan(60));
    final clear = out.getPixel(150, 300);
    expect(clear.r, greaterThan(240));
    expect(clear.g, greaterThan(240));
    final outside = out.getPixel(20, 20);
    expect(outside.b, greaterThan(240));
  });

  test('bakes the pending rotation so the result needs none', () {
    final out = img.decodeJpg(
      StampCompositor.apply(
        whitePage(),
        redStamp(),
        placement: const StampPlacement(centerX: 0.9, centerY: 0.5, widthFraction: 0.1),
        quarterTurns: 1,
      ),
    )!;
    // A portrait page turned once is landscape.
    expect(out.width, 600);
    expect(out.height, 400);
    // Stamp 60×30 centred at (540, 200): right half (x ≥ 540) is red.
    final red = out.getPixel(555, 200);
    expect(red.r, greaterThan(180));
    expect(red.g, lessThan(60));
  });

  test('applies the page filter before stamping', () {
    final grey = img.Image(width: 100, height: 100);
    img.fill(grey, color: img.ColorRgb8(120, 120, 120));
    final out = img.decodeJpg(
      StampCompositor.apply(
        img.encodeJpg(grey),
        redStamp(),
        placement: const StampPlacement(centerX: 0.5, centerY: 0.5, widthFraction: 0.2),
        filter: PageFilter.blackWhite,
      ),
    )!;
    // Black & white turns a flat grey page white...
    final paper = out.getPixel(5, 5);
    expect(paper.r, greaterThan(200));
    // ...and the stamp still lands in colour on top.
    final red = out.getPixel(55, 50);
    expect(red.r, greaterThan(150));
    expect(red.g, lessThan(90));
  });

  test('rotated stamps stay transparent around their corners', () {
    final out = img.decodeJpg(
      StampCompositor.apply(
        whitePage(),
        redStamp(),
        placement: const StampPlacement(centerX: 0.5, centerY: 0.5, widthFraction: 0.5, angle: 0.6),
      ),
    )!;
    // Far corners of the rotated bounding box must not be painted black.
    final corner = out.getPixel(100, 240);
    expect(corner.r, greaterThan(200));
  });

  test('rejects a stamp that is not an image', () {
    expect(
      () => StampCompositor.apply(
        whitePage(),
        Uint8List.fromList([1, 2, 3]),
        placement: const StampPlacement(centerX: 0.5, centerY: 0.5, widthFraction: 0.5),
      ),
      throwsA(anything),
    );
  });
}
