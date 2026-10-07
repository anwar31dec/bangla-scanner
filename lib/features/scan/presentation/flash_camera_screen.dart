import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/dialogs.dart';
import '../../editor/application/page_preview_providers.dart';
import '../data/document_detector.dart';
import 'crop_corners_screen.dart';

/// In-app camera whose flash fires only at the moment a photo is taken (the
/// native scanner can only keep its light on the whole time).
///
/// The live preview is watched for a page; its outline is drawn and, in
/// auto mode, the photo is taken once the page has been held still.
///
/// Each photo goes through [CropCornersScreen] and is flattened into a page
/// file inside [outputDir]. Pops with the page paths, or null if cancelled.
class FlashCameraScreen extends StatefulWidget {
  const FlashCameraScreen({super.key, required this.outputDir});

  final Directory outputDir;

  @override
  State<FlashCameraScreen> createState() => _FlashCameraScreenState();
}

class _FlashCameraScreenState extends State<FlashCameraScreen> with WidgetsBindingObserver {
  /// Longest edge of the copy used to look for the page.
  static const _detectionEdge = 320;

  /// Longest edge of the preview frames analysed live (speed over detail).
  static const _liveEdge = 160;
  static const _liveInterval = Duration(milliseconds: 150);

  /// Corners may wander this much (fraction of the frame) and still count
  /// as holding still.
  static const _steadyTolerance = 0.03;

  /// Consecutive steady frames before auto capture (about a second).
  static const _steadyFramesNeeded = 6;

  /// A page this different from the last captured one is a new page.
  static const _newPageShift = 0.12;

  /// Pause after a capture before auto capture may fire again, so the user
  /// can press Done or move to the next page.
  static const _autoCooldown = Duration(seconds: 2);

  CameraController? _controller;
  bool _failed = false;
  bool _busy = false;
  FlashMode _flash = FlashMode.always;
  bool _auto = true;
  final _pages = <String>[];

  // Live detection state (see _onFrame).
  DocumentQuad? _live;
  int _steadyFrames = 0;
  bool _analyzing = false;
  DateTime _lastAnalysis = DateTime.fromMillisecondsSinceEpoch(0);

  /// Outline of the page last captured, and whether a different page has
  /// been seen since; stops the same page being taken twice.
  DocumentQuad? _lastCaptured;
  bool _armed = true;
  DateTime _autoAllowedAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _locked => _steadyFrames >= _steadyFramesNeeded;

  /// Bumped whenever the camera is opened or closed, so a slow open that
  /// was overtaken (app sent to background) can tell and back off.
  int _session = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _openCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera must be released while the app is not in front.
    if (state == AppLifecycleState.inactive) {
      _session++;
      final controller = _controller;
      if (controller != null) {
        setState(() => _controller = null);
        controller.dispose();
      }
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _openCamera();
    }
  }

  Future<void> _openCamera() async {
    final session = ++_session;
    if (_failed) setState(() => _failed = false);
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw CameraException('no_camera', 'No camera found');
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(camera, ResolutionPreset.ultraHigh, enableAudio: false);
      await controller.initialize();
      await _applyFlash(controller, _flash);
      if (!mounted || session != _session) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await _startLive(controller);
    } catch (_) {
      await controller?.dispose();
      if (mounted && session == _session) setState(() => _failed = true);
    }
  }

  static Future<bool> _applyFlash(CameraController controller, FlashMode mode) async {
    try {
      await controller.setFlashMode(mode);
      return true;
    } on CameraException {
      // No flash on this camera.
      return false;
    }
  }

  Future<void> _cycleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = switch (_flash) {
      FlashMode.always => FlashMode.auto,
      FlashMode.auto => FlashMode.off,
      _ => FlashMode.always,
    };
    if (await _applyFlash(controller, next) && mounted) setState(() => _flash = next);
  }

  Future<void> _startLive(CameraController controller) async {
    try {
      if (!controller.value.isStreamingImages) await controller.startImageStream(_onFrame);
    } catch (_) {
      // Live detection is a convenience; the shutter still works.
    }
  }

  Future<void> _stopLive(CameraController controller) async {
    try {
      if (controller.value.isStreamingImages) await controller.stopImageStream();
    } catch (_) {}
  }

  /// Looks for the page in a preview frame (a few times a second) and
  /// triggers auto capture once it has been held still long enough.
  void _onFrame(CameraImage image) {
    final controller = _controller;
    if (_analyzing || _busy || controller == null || !mounted) return;
    final now = DateTime.now();
    if (now.difference(_lastAnalysis) < _liveInterval) return;
    _lastAnalysis = now;
    _analyzing = true;
    try {
      final frame = _frameLuma(image, _liveEdge);
      var quad = frame == null ? null : DocumentDetector.detectLuma(frame.luma, frame.width, frame.height);
      // Frames arrive the way the sensor is mounted; the preview is upright.
      quad = quad?.rotated(controller.description.sensorOrientation ~/ 90);
      _trackPage(quad);
    } finally {
      _analyzing = false;
    }
  }

  void _trackPage(DocumentQuad? quad) {
    final previous = _live;
    if (quad == null) {
      _steadyFrames = 0;
      _armed = true;
    } else {
      _steadyFrames = previous != null && quad.maxCornerShift(previous) < _steadyTolerance ? _steadyFrames + 1 : 0;
      final captured = _lastCaptured;
      if (captured != null && quad.maxCornerShift(captured) > _newPageShift) _armed = true;
    }
    if (quad != previous || _steadyFrames == _steadyFramesNeeded) setState(() => _live = quad);

    if (quad != null && _auto && _armed && _locked && DateTime.now().isAfter(_autoAllowedAt)) {
      _lastCaptured = quad;
      _armed = false;
      _capture();
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _live = null;
      _steadyFrames = 0;
    });
    String? shotPath;
    try {
      await _stopLive(controller);
      final shot = await controller.takePicture();
      shotPath = shot.path;
      // Freeze on the photo while the user adjusts its corners.
      await controller.pausePreview().catchError((_) {});

      final pixels = await decodePreviewPixels(shot.path, _detectionEdge);
      final detected = await DocumentDetector.detectInBackground(pixels.rgba, pixels.width, pixels.height);
      if (!mounted) return;
      final quad = await Navigator.of(context).push<DocumentQuad>(
        MaterialPageRoute(
          builder: (context) => CropCornersScreen(
            imagePath: shot.path,
            aspectRatio: pixels.width / pixels.height,
            initialQuad: detected ?? DocumentQuad.inset,
          ),
        ),
      );
      if (quad != null) {
        final page = await DocumentDetector.rectifyInBackground(await File(shot.path).readAsBytes(), quad);
        final target = p.join(widget.outputDir.path, 'page_${DateTime.now().microsecondsSinceEpoch}.jpg');
        await File(target).writeAsBytes(page, flush: true);
        _pages.add(target);
      }
    } catch (_) {
      if (mounted) showSnack(context, l10n.scanFailed);
    } finally {
      if (shotPath != null) File(shotPath).delete().ignore();
      if (identical(controller, _controller)) {
        await controller.resumePreview().catchError((_) {});
        if (mounted) await _startLive(controller);
      }
      _autoAllowedAt = DateTime.now().add(_autoCooldown);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    if (_busy) return;
    if (_pages.isNotEmpty) {
      final l10n = context.l10n;
      final discard = await showConfirmDialog(
        context,
        title: l10n.editorDiscardTitle,
        body: l10n.editorDiscardBody,
        confirmLabel: l10n.discard,
        destructive: true,
      );
      if (!discard || !mounted) return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l10n.close,
                      color: Colors.white,
                      icon: const Icon(Icons.close),
                      onPressed: _close,
                    ),
                    const Spacer(),
                    _ModeButton(
                      auto: _auto,
                      onPressed: controller == null || _busy ? null : () => setState(() => _auto = !_auto),
                    ),
                    _FlashButton(mode: _flash, onPressed: controller == null || _busy ? null : _cycleFlash),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (controller != null)
                      CameraPreview(
                        controller,
                        child: CustomPaint(painter: _LiveOutlinePainter(quad: _live, locked: _locked)),
                      )
                    else if (_failed)
                      _CameraError(message: l10n.cameraUnavailable, retryLabel: l10n.retry, onRetry: _openCamera)
                    else
                      const CircularProgressIndicator(color: Colors.white),
                    if (_busy && controller != null) const CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _pages.isEmpty ? null : _LastPage(path: _pages.last, count: _pages.length),
                      ),
                    ),
                    _ShutterButton(
                      label: l10n.cameraTakePhoto,
                      onPressed: controller == null || _busy ? null : _capture,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _pages.isEmpty
                            ? null
                            : FilledButton(
                                onPressed: _busy ? null : () => Navigator.pop(context, List.of(_pages)),
                                child: Text(l10n.done),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brightness of a preview frame, shrunk so its longest edge is at most
/// [maxEdge]. Null for frame layouts we do not understand.
({Uint8List luma, int width, int height})? _frameLuma(CameraImage image, int maxEdge) {
  if (image.planes.isEmpty) return null;
  final plane = image.planes[0];
  final step = math.max(1, (math.max(image.width, image.height) / maxEdge).ceil());
  final width = image.width ~/ step, height = image.height ~/ step;
  if (width < 16 || height < 16) return null;
  final bytes = plane.bytes, stride = plane.bytesPerRow;
  final out = Uint8List(width * height);
  var o = 0;
  switch (image.format.group) {
    case ImageFormatGroup.yuv420:
    case ImageFormatGroup.nv21:
      // The first plane is Y: brightness as is.
      final px = plane.bytesPerPixel ?? 1;
      for (var y = 0; y < height; y++) {
        final row = y * step * stride;
        for (var x = 0; x < width; x++) {
          final i = row + x * step * px;
          out[o++] = i < bytes.length ? bytes[i] : 0;
        }
      }
    case ImageFormatGroup.bgra8888:
      for (var y = 0; y < height; y++) {
        final row = y * step * stride;
        for (var x = 0; x < width; x++) {
          final i = row + x * step * 4;
          out[o++] = i + 2 < bytes.length ? (0.114 * bytes[i] + 0.587 * bytes[i + 1] + 0.299 * bytes[i + 2]).round() : 0;
        }
      }
    default:
      return null;
  }
  return (luma: out, width: width, height: height);
}

/// Draws the page outline found in the live preview: amber while the page
/// is being tracked, green once it is held still.
class _LiveOutlinePainter extends CustomPainter {
  _LiveOutlinePainter({required this.quad, required this.locked});

  final DocumentQuad? quad;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final q = quad;
    if (q == null) return;
    final color = locked ? Colors.lightGreenAccent : Colors.amber;
    final path = Path()
      ..addPolygon([for (final c in q.corners) Offset(c.x * size.width, c.y * size.height)], true);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: locked ? 0.25 : 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = locked ? 4 : 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_LiveOutlinePainter old) => old.quad != quad || old.locked != locked;
}

/// Auto capture (photo taken by itself once the page is held still) or
/// manual (shutter button only).
class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.auto, required this.onPressed});

  final bool auto;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: Colors.white, disabledForegroundColor: Colors.white54),
      icon: Icon(auto ? Icons.motion_photos_auto_outlined : Icons.touch_app_outlined),
      label: Text(auto ? l10n.captureAuto : l10n.captureManual),
    );
  }
}

/// Cycles flash on → auto → off. "On" lights up only while the photo is
/// taken.
class _FlashButton extends StatelessWidget {
  const _FlashButton({required this.mode, required this.onPressed});

  final FlashMode mode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, label) = switch (mode) {
      FlashMode.always => (Icons.flash_on, l10n.flashOn),
      FlashMode.auto => (Icons.flash_auto, l10n.flashAuto),
      _ => (Icons.flash_off, l10n.flashOff),
    };
    final color = mode == FlashMode.off ? Colors.white : Colors.amber;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color, disabledForegroundColor: color.withValues(alpha: 0.5)),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: Colors.white54, width: 5)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onPressed, child: const SizedBox.square(dimension: 76)),
        ),
      ),
    );
  }
}

/// Thumbnail of the newest page with the number of pages taken so far.
class _LastPage extends StatelessWidget {
  const _LastPage({required this.path, required this.count});

  final String path;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      count: count,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          key: ValueKey(path),
          width: 52,
          height: 68,
          fit: BoxFit.cover,
          cacheWidth: 160,
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.retryLabel, required this.onRetry});

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 48, color: Colors.white70),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
