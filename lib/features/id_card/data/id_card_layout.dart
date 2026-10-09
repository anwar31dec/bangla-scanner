import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/models/enums.dart';
import '../../export/data/image_processing.dart';

/// Places the sides of a card (NID, passport page…) on one A4 page at real
/// size. Pure Dart; runs in a background isolate.
class IdCardLayout {
  IdCardLayout._();

  /// ISO/IEC 7810 ID-1 (bank cards, Bangladesh NID smart card).
  static const cardWidthMm = 85.6;
  static const cardHeightMm = 53.98;

  static const a4WidthMm = 210.0;
  static const a4HeightMm = 297.0;

  /// Vertical gap between two sides.
  static const gapMm = 20.0;

  /// Rendered at 300 dpi; the save pipeline downsizes for lower qualities.
  static const dpi = 300;

  static int mmToPx(double mm, {int dpi = dpi}) => (mm / 25.4 * dpi).round();

  /// Runs [compose] in a background isolate.
  ///
  /// Call this instead of wrapping [compose] in `Isolate.run` inside a
  /// widget: a closure created there also carries the widget's State, which
  /// cannot be sent to another isolate.
  static Future<Uint8List> composeInBackground(
    Uint8List front,
    Uint8List back, {
    bool flipFront = false,
    bool flipBack = false,
  }) =>
      Isolate.run(() => compose(front, back, flipFront: flipFront, flipBack: flipBack));

  /// Like [composeInBackground] for any [kind] and one or two sides.
  static Future<Uint8List> composeSidesInBackground(
    List<Uint8List> sides, {
    required CardKind kind,
    List<bool> flipped = const [],
  }) =>
      Isolate.run(() => composeSides(sides, kind: kind, flipped: flipped));

  /// Returns a high quality JPEG of the A4 page with an ID-1 card's front
  /// and back. [flipFront] / [flipBack] turn a side by 180° (for a card that
  /// was photographed upside down).
  static Uint8List compose(Uint8List front, Uint8List back, {bool flipFront = false, bool flipBack = false}) =>
      composeSides([front, back], kind: CardKind.idCard, flipped: [flipFront, flipBack]);

  /// Returns a high quality JPEG of an A4 page with [sides] (one or more)
  /// stacked and centred at the real size of [kind]. [flipped] turns the
  /// matching side by 180°.
  static Uint8List composeSides(List<Uint8List> sides, {required CardKind kind, List<bool> flipped = const []}) {
    if (sides.isEmpty) throw ArgumentError('At least one side is needed');
    final pageW = mmToPx(a4WidthMm), pageH = mmToPx(a4HeightMm);
    final cardW = mmToPx(kind.widthMm), cardH = mmToPx(kind.heightMm);
    final gap = mmToPx(gapMm);

    final page = img.Image(width: pageW, height: pageH);
    img.fill(page, color: img.ColorRgb8(255, 255, 255));

    final left = (pageW - cardW) ~/ 2;
    final top = (pageH - (cardH * sides.length + gap * (sides.length - 1))) ~/ 2;

    for (var i = 0; i < sides.length; i++) {
      var card = fitCard(ImageProcessing.decode(sides[i]), cardW, cardH);
      if (i < flipped.length && flipped[i]) card = ImageProcessing.rotateQuarterTurns(card, 2);
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
