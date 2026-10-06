import 'package:banglascanner/features/id_card/data/id_card_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('cards keep real ID-1 proportions after fitting', () {
    final portraitPhoto = img.Image(width: 900, height: 1500);
    final card = IdCardLayout.fitCard(portraitPhoto, 1011, 638);
    expect([card.width, card.height], [1011, 638]);
  });

  test('composes in a background isolate', () async {
    final side = img.encodeJpg(img.Image(width: 856, height: 540));
    final page = img.decodeJpg(await IdCardLayout.composeInBackground(side, side))!;
    expect([page.width, page.height], [2480, 3508]);
  });

  test('a flipped side is placed turned by 180°', () {
    // Left half red, right half blue.
    final card = img.Image(width: 856, height: 540);
    img.fillRect(card, x1: 0, y1: 0, x2: 427, y2: 539, color: img.ColorRgb8(200, 0, 0));
    img.fillRect(card, x1: 428, y1: 0, x2: 855, y2: 539, color: img.ColorRgb8(0, 0, 200));
    final side = img.encodeJpg(card);

    final page = img.decodeJpg(IdCardLayout.compose(side, side, flipBack: true))!;
    final cardW = IdCardLayout.mmToPx(IdCardLayout.cardWidthMm);
    final cardH = IdCardLayout.mmToPx(IdCardLayout.cardHeightMm);
    final gap = IdCardLayout.mmToPx(IdCardLayout.gapMm);
    final left = (page.width - cardW) ~/ 2;
    final top = (page.height - (cardH * 2 + gap)) ~/ 2;

    final frontLeft = page.getPixel(left + cardW ~/ 4, top + cardH ~/ 2);
    final backLeft = page.getPixel(left + cardW ~/ 4, top + cardH + gap + cardH ~/ 2);
    expect(frontLeft.r > 150 && frontLeft.b < 60, isTrue, reason: 'front keeps red on the left');
    expect(backLeft.b > 150 && backLeft.r < 60, isTrue, reason: 'flipped back has blue on the left');
  });

  test('composes both sides centred on an A4 page at 300 dpi', () {
    img.Image solid(int r, int g, int b) => img.fill(img.Image(width: 856, height: 540), color: img.ColorRgb8(r, g, b));
    final front = img.encodeJpg(solid(200, 0, 0));
    final back = img.encodeJpg(solid(0, 0, 200));

    final page = img.decodeJpg(IdCardLayout.compose(front, back))!;
    expect([page.width, page.height], [2480, 3508]);

    final cardW = IdCardLayout.mmToPx(IdCardLayout.cardWidthMm);
    final cardH = IdCardLayout.mmToPx(IdCardLayout.cardHeightMm);
    final gap = IdCardLayout.mmToPx(IdCardLayout.gapMm);
    final left = (2480 - cardW) ~/ 2;
    final top = (3508 - (cardH * 2 + gap)) ~/ 2;

    expect(cardW, 1011); // 85.6 mm at 300 dpi
    final frontPx = page.getPixel(left + cardW ~/ 2, top + cardH ~/ 2);
    final backPx = page.getPixel(left + cardW ~/ 2, top + cardH + gap + cardH ~/ 2);
    final marginPx = page.getPixel(left ~/ 2, top + cardH ~/ 2);
    expect(frontPx.r > 150 && frontPx.b < 60, isTrue, reason: 'front is red');
    expect(backPx.b > 150 && backPx.r < 60, isTrue, reason: 'back is blue');
    expect(marginPx.r > 245 && marginPx.g > 245, isTrue, reason: 'margin is white');
    // Symmetric horizontal margins.
    expect((2480 - (left + cardW)) - left, lessThanOrEqualTo(1));
  });
}
