import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../export/data/image_processing.dart';

/// A page image file at a given preview size. [revision] is part of the key
/// so a changed file (after cropping) is decoded again.
typedef PreviewSource = ({String path, int revision, int maxEdge});

/// Raw RGBA pixels of a page, scaled down for the screen.
typedef PreviewPixels = ({Uint8List rgba, int width, int height});

/// Top-level on purpose: a closure created inside a provider would carry
/// its `ref` with it, and that cannot be sent to another isolate.
Future<Uint8List> _filterInBackground(PreviewPixels pixels, PageFilter filter) =>
    Isolate.run(() => ImageProcessing.previewJpeg(pixels.rgba, pixels.width, pixels.height, filter));

/// Decodes an image file with the platform codec, scaled down so its longest
/// edge is at most [maxEdge]. Much faster than a full decode in Dart.
Future<PreviewPixels> decodePreviewPixels(String path, int maxEdge) async {
  final buffer = await ui.ImmutableBuffer.fromFilePath(path);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final longest = math.max(descriptor.width, descriptor.height);
    // Only the width is given so the codec keeps the aspect ratio.
    final targetWidth = longest > maxEdge ? (descriptor.width * maxEdge / longest).round() : null;
    codec = await descriptor.instantiateCodec(targetWidth: targetWidth == null ? null : math.max(1, targetWidth));
    image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    if (data == null) throw StateError('Could not read pixels of $path');
    return (rgba: data.buffer.asUint8List(), width: image.width, height: image.height);
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}

/// Decodes a page at preview size with the platform codec. Shared by all
/// filters of the page, so trying another filter does not decode again.
final previewPixelsProvider = FutureProvider.autoDispose.family<PreviewPixels, PreviewSource>(
  (ref, source) => decodePreviewPixels(source.path, source.maxEdge),
  // An unreadable file stays unreadable.
  retry: (_, _) => null,
);

/// JPEG of a page with [filter] applied by the same code that runs on save,
/// so the preview shows what the saved document will look like.
final filteredPreviewProvider =
    FutureProvider.autoDispose.family<Uint8List, ({PreviewSource source, PageFilter filter})>(
  (ref, request) async {
    final pixels = await ref.watch(previewPixelsProvider(request.source).future);
    return _filterInBackground(pixels, request.filter);
  },
  retry: (_, _) => null,
);
