import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../../core/models/enums.dart';
import '../../../core/utils/app_exception.dart';
import '../../export/data/image_processing.dart';
import '../../scan/data/draft_document.dart';

/// Where a signature or stamp sits on a page, independent of pixel size.
/// Coordinates refer to the page as the user sees it (after rotation).
@immutable
class StampPlacement {
  const StampPlacement({required this.centerX, required this.centerY, required this.widthFraction, this.angle = 0});

  /// Centre of the stamp, 0…1 across the page width.
  final double centerX;

  /// Centre of the stamp, 0…1 down the page height.
  final double centerY;

  /// Stamp width as a fraction of the page width (0…1).
  final double widthFraction;

  /// Clockwise rotation in radians.
  final double angle;

  StampPlacement copyWith({double? centerX, double? centerY, double? widthFraction, double? angle}) => StampPlacement(
    centerX: centerX ?? this.centerX,
    centerY: centerY ?? this.centerY,
    widthFraction: widthFraction ?? this.widthFraction,
    angle: angle ?? this.angle,
  );

  @override
  bool operator ==(Object other) =>
      other is StampPlacement &&
      other.centerX == centerX &&
      other.centerY == centerY &&
      other.widthFraction == widthFraction &&
      other.angle == angle;

  @override
  int get hashCode => Object.hash(centerX, centerY, widthFraction, angle);
}

/// Burns a signature or stamp (a PNG with transparency) into a page image.
/// Pure Dart, runs in a background isolate.
class StampCompositor {
  StampCompositor._();

  /// JPEG quality of the flattened page. It is an intermediate file that
  /// is compressed again on save, so keep it high.
  static const jpegQuality = 92;

  /// Returns [pageBytes] with its [quarterTurns], [filter] and
  /// [adjustments] applied and [stampPng] drawn at [placement]. The result
  /// is what the user saw in the editor, so the page continues with
  /// [PageFilter.original] and no rotation.
  static Uint8List apply(
    Uint8List pageBytes,
    Uint8List stampPng, {
    required StampPlacement placement,
    int quarterTurns = 0,
    PageFilter filter = PageFilter.original,
    PageAdjustments adjustments = PageAdjustments.none,
  }) {
    var page = ImageProcessing.decode(pageBytes);
    page = ImageProcessing.rotateQuarterTurns(page, quarterTurns);
    page = ImageProcessing.applyFilter(page, filter, adjustments: adjustments);

    final stamp = _decodeStamp(stampPng);
    final targetWidth = math.max(1, (placement.widthFraction.clamp(0.01, 2.0) * page.width).round());
    var scaled = img.copyResize(
      stamp,
      width: targetWidth,
      height: math.max(1, (stamp.height * targetWidth / stamp.width).round()),
      interpolation: img.Interpolation.linear,
    );
    if (placement.angle != 0) {
      scaled = img.copyRotate(scaled, angle: placement.angle * 180 / math.pi, interpolation: img.Interpolation.linear);
    }
    final dstX = (placement.centerX * page.width - scaled.width / 2).round();
    final dstY = (placement.centerY * page.height - scaled.height / 2).round();
    img.compositeImage(page, scaled, dstX: dstX, dstY: dstY);
    return img.encodeJpg(page, quality: jpegQuality);
  }

  /// Decodes the stamp as 8-bit RGBA so the alpha channel blends.
  static img.Image _decodeStamp(Uint8List png) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(png);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null || decoded.width == 0 || decoded.height == 0) {
      throw const AppException(AppErrorKind.corruptFile);
    }
    if (decoded.numChannels != 4 || decoded.format != img.Format.uint8 || decoded.hasPalette) {
      return decoded.convert(numChannels: 4, format: img.Format.uint8, alpha: 255);
    }
    return decoded;
  }
}
