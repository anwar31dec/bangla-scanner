import 'package:flutter/foundation.dart';

import '../../../core/models/enums.dart';

/// One page of the document being scanned or edited. Edits are stored as
/// parameters (rotation, filter) and only "baked" into pixels on save, so
/// they are instant and reversible.
@immutable
class DraftPage {
  const DraftPage({
    required this.id,
    required this.imagePath,
    this.quarterTurns = 0,
    this.filter = PageFilter.original,
    this.revision = 0,
  });

  final String id;

  /// Working copy inside the app's temp folder (never the user's original).
  final String imagePath;

  /// Clockwise rotation in 90° steps.
  final int quarterTurns;
  final PageFilter filter;

  /// Bumped when the image file changes (e.g. after cropping) so image
  /// caches are refreshed.
  final int revision;

  DraftPage copyWith({String? imagePath, int? quarterTurns, PageFilter? filter, int? revision}) => DraftPage(
        id: id,
        imagePath: imagePath ?? this.imagePath,
        quarterTurns: quarterTurns ?? this.quarterTurns,
        filter: filter ?? this.filter,
        revision: revision ?? this.revision,
      );
}

/// The document currently being built in the editor.
@immutable
class DraftDocument {
  const DraftDocument({
    required this.workDirPath,
    required this.pages,
    this.existingDocumentId,
    this.existingName,
    this.existingFormat,
  });

  /// Folder that holds this draft's working images.
  final String workDirPath;
  final List<DraftPage> pages;

  /// Set when editing a document that is already in the library; saving
  /// then replaces that document instead of creating a new one.
  final String? existingDocumentId;
  final String? existingName;
  final SaveFormat? existingFormat;

  DraftDocument copyWith({List<DraftPage>? pages}) => DraftDocument(
        workDirPath: workDirPath,
        pages: pages ?? this.pages,
        existingDocumentId: existingDocumentId,
        existingName: existingName,
        existingFormat: existingFormat,
      );
}
