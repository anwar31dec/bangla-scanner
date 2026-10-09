import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../editor/presentation/page_preview.dart';
import '../../scan/data/draft_document.dart';
import '../data/stamp_compositor.dart';

/// Shows the page with the stamp on top; the user drags it into place and
/// pinches to resize or rotate. Returns the [StampPlacement], or null.
class StampPlacementScreen extends StatefulWidget {
  const StampPlacementScreen({super.key, required this.page, required this.stampPng});

  final DraftPage page;
  final Uint8List stampPng;

  @override
  State<StampPlacementScreen> createState() => _StampPlacementScreenState();
}

class _StampPlacementScreenState extends State<StampPlacementScreen> {
  /// Width ÷ height of the page as displayed (rotation applied).
  double? _pageAspect;

  /// Width ÷ height of the stamp image.
  double? _stampAspect;

  // Starts bottom-right, where signatures usually go.
  var _placement = const StampPlacement(centerX: 0.7, centerY: 0.82, widthFraction: 0.35);
  StampPlacement? _gestureStart;

  @override
  void initState() {
    super.initState();
    _loadSizes();
  }

  Future<void> _loadSizes() async {
    final page = await _imageSize(await ui.ImmutableBuffer.fromFilePath(widget.page.imagePath));
    final stamp = await _imageSize(await ui.ImmutableBuffer.fromUint8List(widget.stampPng));
    if (!mounted) return;
    final rotated = widget.page.quarterTurns.isOdd;
    setState(() {
      _pageAspect = rotated ? page.height / page.width : page.width / page.height;
      _stampAspect = stamp.width / stamp.height;
    });
  }

  /// Size of the first frame as the engine shows it (EXIF orientation
  /// applied). Decoded tiny: only the aspect ratio matters.
  static Future<Size> _imageSize(ui.ImmutableBuffer buffer) async {
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      codec = await descriptor.instantiateCodec(targetWidth: 64);
      image = (await codec.getNextFrame()).image;
      return Size(image.width.toDouble(), image.height.toDouble());
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  /// Where the page is drawn inside [box] with BoxFit.contain.
  Rect _pageRect(Size box) {
    final aspect = _pageAspect ?? 0.707;
    var w = box.width, h = w / aspect;
    if (h > box.height) {
      h = box.height;
      w = h * aspect;
    }
    return Rect.fromCenter(center: box.center(Offset.zero), width: w, height: h);
  }

  void _onScaleStart(ScaleStartDetails d) => _gestureStart = _placement;

  void _onScaleUpdate(ScaleUpdateDetails d, Rect page) {
    final start = _gestureStart ?? _placement;
    setState(() {
      _placement = StampPlacement(
        centerX: (_placement.centerX + d.focalPointDelta.dx / page.width).clamp(0.0, 1.0),
        centerY: (_placement.centerY + d.focalPointDelta.dy / page.height).clamp(0.0, 1.0),
        widthFraction: (start.widthFraction * d.scale).clamp(0.05, 1.0),
        angle: start.angle + d.rotation,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ready = _pageAspect != null && _stampAspect != null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.placeStampTitle),
        actions: [
          TextButton.icon(
            onPressed: ready ? () => Navigator.pop(context, _placement) : null,
            icon: const Icon(Icons.check),
            label: Text(l10n.done),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final box = constraints.biggest;
                  final page = _pageRect(box);
                  final stampW = _placement.widthFraction * page.width;
                  final stampH = stampW / (_stampAspect ?? 2);
                  final center = Offset(
                    page.left + _placement.centerX * page.width,
                    page.top + _placement.centerY * page.height,
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: (d) => _onScaleUpdate(d, page),
                    child: Stack(
                      children: [
                        Positioned.fromRect(
                          rect: page,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12)],
                            ),
                            child: PagePreview(page: widget.page, fit: BoxFit.fill),
                          ),
                        ),
                        if (ready)
                          Positioned(
                            left: center.dx - stampW / 2,
                            top: center.dy - stampH / 2,
                            width: stampW,
                            height: stampH,
                            child: Transform.rotate(
                              angle: _placement.angle,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                                ),
                                child: Image.memory(widget.stampPng, fit: BoxFit.fill, gaplessPlayback: true),
                              ),
                            ),
                          )
                        else
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.photo_size_select_small_outlined, size: 20),
                Expanded(
                  child: Slider(
                    value: _placement.widthFraction,
                    min: 0.05,
                    max: 1.0,
                    label: l10n.stampSize,
                    onChanged: ready ? (v) => setState(() => _placement = _placement.copyWith(widthFraction: v)) : null,
                  ),
                ),
                const Icon(Icons.photo_size_select_large_outlined, size: 24),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.resetRotation,
                  icon: const Icon(Icons.rotate_left),
                  onPressed: _placement.angle == 0
                      ? null
                      : () => setState(() => _placement = _placement.copyWith(angle: 0)),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(l10n.placeStampHint, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
