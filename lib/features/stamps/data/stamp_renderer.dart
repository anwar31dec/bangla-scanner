import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Colours a text stamp can be printed in.
enum StampColor {
  blue(Color(0xFF1B4FBF)),
  red(Color(0xFFC62828)),
  black(Color(0xFF1A1A1A));

  const StampColor(this.color);

  final Color color;
}

/// Draws rubber-stamp style text (a date, "Attested", custom text) into a
/// transparent PNG with the app font, so Bangla renders correctly. Uses
/// the Flutter engine, so it runs on the main isolate; the images are small.
class StampRenderer {
  StampRenderer._();

  /// Height of the text in pixels. The stamp is scaled when placed, so this
  /// only needs to be large enough to stay sharp on a 300 dpi page.
  static const fontSize = 110.0;
  static const _padding = 34.0;
  static const _stroke = 9.0;

  static Future<Uint8List> renderText(String text, {required StampColor color, bool border = true}) async {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color.color,
          height: 1.15,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final width = painter.width + 2 * _padding;
    final height = painter.height + 2 * _padding;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (border) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(_stroke / 2, _stroke / 2, width - _stroke, height - _stroke),
        const Radius.circular(26),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..color = color.color,
      );
    }
    painter.paint(canvas, const Offset(_padding, _padding));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.ceil(), height.ceil());
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode stamp');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
      painter.dispose();
    }
  }
}
