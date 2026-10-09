import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/dialogs.dart';

/// Full-screen pad to draw a signature with a finger. Returns the drawing
/// as a transparent PNG (cropped to the ink), or null when cancelled.
class SignaturePadScreen extends StatefulWidget {
  const SignaturePadScreen({super.key});

  /// Pixels per logical pixel in the exported PNG. A signature drawn
  /// across a phone screen comes out about 1000 px wide.
  static const exportScale = 3.0;

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _Stroke {
  _Stroke(this.color, this.width);

  final Color color;
  final double width;
  final List<Offset> points = [];
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  static const _penWidths = [2.5, 4.0, 6.5];
  static const _colors = [Color(0xFF111111), Color(0xFF1B4FBF)];

  final List<_Stroke> _strokes = [];
  double _penWidth = _penWidths[1];
  Color _color = _colors[0];

  void _start(Offset point) => setState(() => _strokes.add(_Stroke(_color, _penWidth)..points.add(point)));

  void _move(Offset point) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.points.add(point));
  }

  Future<void> _done() async {
    final l10n = context.l10n;
    if (_strokes.isEmpty) {
      showSnack(context, l10n.signatureEmpty);
      return;
    }
    final png = await _export();
    if (mounted) Navigator.pop(context, png);
  }

  /// Draws the strokes at [SignaturePadScreen.exportScale], cropped to the
  /// ink with a small margin.
  Future<Uint8List> _export() async {
    var bounds = Rect.zero;
    var first = true;
    for (final s in _strokes) {
      for (final pt in s.points) {
        final r = Rect.fromCircle(center: pt, radius: s.width);
        bounds = first ? r : bounds.expandToInclude(r);
        first = false;
      }
    }
    bounds = bounds.inflate(8);
    const scale = SignaturePadScreen.exportScale;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(scale)
      ..translate(-bounds.left, -bounds.top);
    _SignaturePainter(_strokes).paint(canvas, bounds.size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      math.max(1, (bounds.width * scale).ceil()),
      math.max(1, (bounds.height * scale).ceil()),
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signaturePadTitle),
        actions: [
          IconButton(
            tooltip: l10n.undo,
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.removeLast()),
          ),
          IconButton(
            tooltip: l10n.clear,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _strokes.isEmpty ? null : () => setState(_strokes.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.signaturePadHint, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Baseline, like the line on a form.
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 56,
                      child: Container(height: 1.5, color: theme.colorScheme.outlineVariant),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) => _start(d.localPosition),
                      onPanUpdate: (d) => _move(d.localPosition),
                      child: CustomPaint(painter: _SignaturePainter(_strokes)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(l10n.penThickness, style: theme.textTheme.labelLarge),
                const SizedBox(width: 12),
                for (final w in _penWidths)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PenChip(
                      width: w,
                      selected: _penWidth == w,
                      color: _color,
                      onTap: () => setState(() => _penWidth = w),
                    ),
                  ),
                const Spacer(),
                for (final c in _colors)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _ColorDot(color: c, selected: _color == c, onTap: () => setState(() => _color = c)),
                  ),
              ],
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
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _strokes.isEmpty ? null : _done,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.saveSignature),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);

  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      // Quadratic smoothing through the midpoints keeps curves soft.
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length - 1; i++) {
        final a = s.points[i], b = s.points[i + 1];
        final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
        path.quadraticBezierTo(a.dx, a.dy, mid.dx, mid.dy);
      }
      path.lineTo(s.points.last.dx, s.points.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}

class _PenChip extends StatelessWidget {
  const _PenChip({required this.width, required this.selected, required this.color, required this.onTap});

  final double width;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
        ),
        child: Center(
          child: Container(
            width: width * 2.2,
            height: width * 2.2,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 3),
        ),
        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
      ),
    );
  }
}
