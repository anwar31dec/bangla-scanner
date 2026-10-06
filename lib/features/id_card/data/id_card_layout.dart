import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../export/data/image_processing.dart';

/// Places the front and back of an ID card on one A4 page at real size.
/// Pure Dart; runs in a background isolate.
class IdCardLayout {
  IdCardLayout._();

  /// ISO/IEC 7810 ID-1 (bank cards, Bangladesh NID smart card).
  static const cardWidthMm = 85.6;
  static const cardHeightMm = 53.98;

  static const a4WidthMm = 210.0;
  static const a4HeightMm = 297.0;

  /// Vertical gap between the two sides.
  static const gapMm = 20.0;

  /// Rendered at 300 dpi; the save pipeline downsizes for lower qualities.
  static const dpi = 300;

  static int mmToPx(double mm, {int dpi = dpi}) => (mm / 25.4 * dpi).round();

  /// Returns a high quality JPEG of the A4 page.
  static Uint8List compose(Uint8List front, Uint8List back) {
    final pageW = mmToPx(a4WidthMm), pageH = mmToPx(a4HeightMm);
    final cardW = mmToPx(cardWidthMm), cardH = mmToPx(cardHeightMm);
    final gap = mmToPx(gapMm);

    final page = img.Image(width: pageW, height: pageH);
    img.fill(page, color: img.ColorRgb8(255, 255, 255));

    final left = (pageW - cardW) ~/ 2;
    final top = (pageH - (cardH * 2 + gap)) ~/ 2;

    final sides = [front, back];
    for (var i = 0; i < sides.length; i++) {
      final card = fitCard(ImageProcessing.decode(sides[i]), cardW, cardH);
      final y = top + i * (cardH + gap);
      img.compositeImage(page, card, dstX: left, dstY: y);
      // Thin light outline makes the card easy to cut out after printing.
      img.drawRect(page, x1: left - 1, y1: y - 1, x2: left + cardW, y2: y + cardH, color: img.ColorRgb8(200, 200, 200));
    }
    return img.encodeJpg(page, quality: 95);
  }

  /// Turns the photo landscape, then scales it to cover exactly
  /// [width]×[height] and crops the overflow evenly (keeps proportions).
  static img.Image fitCard(img.Image src, int width, int height) {
    var image = src.height > src.width ? img.copyRotate(src, angle: 90) : src;
    final scale = [width / image.width, height / image.height].reduce((a, b) => a > b ? a : b);
    image = img.copyResize(
      image,
      width: (image.width * scale).ceil(),
      height: (image.height * scale).ceil(),
      interpolation: img.Interpolation.average,
    );
    return img.copyCrop(
      image,
      x: (image.width - width) ~/ 2,
      y: (image.height - height) ~/ 2,
      width: width,
      height: height,
    );
  }
}
