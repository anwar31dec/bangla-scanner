import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../scan/data/draft_document.dart';
import '../application/page_preview_providers.dart';

/// Shows a draft page with its rotation and filter applied.
class PagePreview extends ConsumerStatefulWidget {
  const PagePreview({super.key, required this.page, this.cacheWidth, this.fit = BoxFit.contain});

  /// Longest edge of the filtered preview when no [cacheWidth] is given.
  /// About the size of a page on a phone screen.
  static const fullSize = 1200;

  final DraftPage page;

  /// Decode size for thumbnails (saves memory and time in long lists).
  final int? cacheWidth;
  final BoxFit fit;

  @override
  ConsumerState<PagePreview> createState() => _PagePreviewState();
}

class _PagePreviewState extends ConsumerState<PagePreview> {
  /// The last filtered image that finished rendering. Kept on screen while
  /// the next filter is computed so switching filters never flashes.
  Uint8List? _filtered;

  @override
  void didUpdateWidget(PagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.page, page = widget.page;
    if (old.imagePath != page.imagePath || old.revision != page.revision) _filtered = null;
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    if (page.filter == PageFilter.original) {
      _filtered = null;
    } else {
      final preview = ref.watch(
        filteredPreviewProvider((
          source: (path: page.imagePath, revision: page.revision, maxEdge: widget.cacheWidth ?? PagePreview.fullSize),
          filter: page.filter,
        )),
      );
      // On error the unfiltered image below shows instead.
      if (preview.hasValue) _filtered = preview.value;
    }

    final filtered = _filtered;
    // Same key for both sources so gaplessPlayback bridges the switch
    // between the file and the filtered bytes.
    final key = ValueKey('${page.imagePath}#${page.revision}');
    final image = filtered != null
        ? Image.memory(filtered, key: key, fit: widget.fit, gaplessPlayback: true)
        : Image.file(
            File(page.imagePath),
            key: key,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => const ColoredBox(
              color: Colors.black12,
              child: Center(child: Icon(Icons.broken_image_outlined, size: 40)),
            ),
          );
    return RotatedBox(quarterTurns: page.quarterTurns, child: image);
  }
}
