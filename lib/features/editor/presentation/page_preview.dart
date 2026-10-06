import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../scan/data/draft_document.dart';

/// Fast on-screen approximation of each filter using a GPU colour matrix.
/// The exact filter (adaptive threshold etc.) is applied on save.
ColorFilter? previewColorFilter(PageFilter filter) {
  const r = 0.299, g = 0.587, b = 0.114;
  switch (filter) {
    case PageFilter.original:
      return null;
    case PageFilter.grayscale:
      return const ColorFilter.matrix([
        r, g, b, 0, 0, //
        r, g, b, 0, 0,
        r, g, b, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case PageFilter.blackWhite:
      // Grayscale with very high contrast around mid-grey.
      const k = 4.0, o = -128 * (k - 1);
      return const ColorFilter.matrix([
        r * k, g * k, b * k, 0, o, //
        r * k, g * k, b * k, 0, o,
        r * k, g * k, b * k, 0, o,
        0, 0, 0, 1, 0,
      ]);
    case PageFilter.enhanced:
      const c = 1.25, o = -128 * (c - 1) + 10;
      return const ColorFilter.matrix([
        c, 0, 0, 0, o, //
        0, c, 0, 0, o,
        0, 0, c, 0, o,
        0, 0, 0, 1, 0,
      ]);
  }
}

/// Shows a draft page with its rotation and filter applied.
class PagePreview extends StatelessWidget {
  const PagePreview({super.key, required this.page, this.cacheWidth, this.fit = BoxFit.contain});

  final DraftPage page;

  /// Decode width for thumbnails (saves memory in long lists).
  final int? cacheWidth;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.file(
      File(page.imagePath),
      key: ValueKey('${page.imagePath}#${page.revision}'),
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => const ColoredBox(
        color: Colors.black12,
        child: Center(child: Icon(Icons.broken_image_outlined, size: 40)),
      ),
    );
    final filter = previewColorFilter(page.filter);
    if (filter != null) image = ColorFiltered(colorFilter: filter, child: image);
    return RotatedBox(quarterTurns: page.quarterTurns, child: image);
  }
}
