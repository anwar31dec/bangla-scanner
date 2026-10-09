import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../data/document_detector.dart';

/// Shows a photo with the detected page outline and lets the user drag the
/// four corners. Pops with the chosen [DocumentQuad], or null to retake.
class CropCornersScreen extends StatefulWidget {
  const CropCornersScreen({
    super.key,
    required this.imagePath,
    required this.aspectRatio,
    required this.initialQuad,
  });

  final String imagePath;

  /// Width / height of the photo as displayed (orientation applied).
  final double aspectRatio;
  final DocumentQuad initialQuad;

  @override
  State<CropCornersScreen> createState() => _CropCornersScreenState();
}

class _CropCornersScreenState extends State<CropCornersScreen> {
  /// Room around the photo so corners on its edge can still be grabbed.
  static const _margin = 28.0;
  static const _grabRadius = 44.0;

  late DocumentQuad _quad = widget.initialQuad;
  int? _active;

  Rect _photoRect(Size area) {
    final maxW = area.width - 2 * _margin, maxH = area.height - 2 * _margin;
    var w = maxW, h = w / widget.aspectRatio;
    if (h > maxH) {
      h = maxH;
      w = h * widget.aspectRatio;
    }
    return Rect.fromLTWH((area.width - w) / 2, (area.height - h) / 2, w, h);
  }

  List<Offset> _cornerOffsets(Rect photo) =>
      [for (final c in _quad.corners) Offset(photo.left + c.x * photo.width, photo.top + c.y * photo.height)];

  void _grab(Offset position, Rect photo) {
    final corners = _cornerOffsets(photo);
    int? nearest;
    var best = _grabRadius;
    for (var i = 0; i < corners.length; i++) {
      final distance = (corners[i] - position).distance;
      if (distance < best) {
        best = distance;
        nearest = i;
      }
    }
    setState(() => _active = nearest);
  }

  void _drag(Offset delta, Rect photo) {
    final index = _active;
    if (index == null) return;
    final moved = _cornerOffsets(photo)[index] + delta;
    final candidate = _quad.withCorner(index, (
      x: ((moved.dx - photo.left) / photo.width).clamp(0.0, 1.0).toDouble(),
      y: ((moved.dy - photo.top) / photo.height).clamp(0.0, 1.0).toDouble(),
    ));
    // Keep a shape that can be flattened into a page.
    if (candidate.isConvex) setState(() => _quad = candidate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cropCornersTitle),
        actions: [
          IconButton(
            tooltip: l10n.cropWholePhoto,
            icon: const Icon(Icons.crop_free),
            onPressed: () => setState(() => _quad = DocumentQuad.full),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.cropCornersHint, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ),
          Expanded(
            child: ColoredBox(
              color: Colors.black,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final photo = _photoRect(constraints.biggest);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _grab(details.localPosition, photo),
                    onPanUpdate: (details) => _drag(details.delta, photo),
                    onPanEnd: (_) => setState(() => _active = null),
                    onPanCancel: () => setState(() => _active = null),
                    child: Stack(
                      children: [
                        Positioned.fromRect(
                          rect: photo,
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.fill,
                            gaplessPlayback: true,
                            cacheWidth: (photo.width * MediaQuery.devicePixelRatioOf(context)).round(),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _QuadPainter(
                              corners: _cornerOffsets(photo),
                              active: _active,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.cameraRetake),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _quad),
                  icon: const Icon(Icons.check),
                  label: Text(l10n.cameraUsePage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dims everything outside the page outline and draws the corner handles.
class _QuadPainter extends CustomPainter {
  _QuadPainter({required this.corners, required this.active, required this.color});

  final List<Offset> corners;
  final int? active;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()..addPolygon(corners, true);
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), outline),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    for (var i = 0; i < corners.length; i++) {
      final radius = i == active ? 17.0 : 11.0;
      canvas.drawCircle(corners[i], radius, Paint()..color = Colors.white.withValues(alpha: i == active ? 0.35 : 1));
      canvas.drawCircle(
        corners[i],
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_QuadPainter old) => old.active != active || old.color != color || !_same(old.corners, corners);

  static bool _same(List<Offset> a, List<Offset> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
