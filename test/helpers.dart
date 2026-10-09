import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A synthetic "document photo": light page with dark text-like bars and a
/// shadow gradient on one side.
Uint8List fakeDocumentJpeg({int width = 600, int height = 800}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final shade = 220 - (x * 90 ~/ width); // shadow towards the right
      final isText = (y ~/ 20).isEven && y % 20 < 6 && x > 40 && x < width - 40;
      final v = isText ? shade - 150 : shade;
      image.setPixelRgb(x, y, v, v, v + 5);
    }
  }
  return img.encodeJpg(image, quality: 90);
}
