import 'package:flutter/foundation.dart';

import '../../../core/models/enums.dart';

/// Manual tone controls applied on top of a page's filter.
@immutable
class PageAdjustments {
  const PageAdjustments({this.strength = 1.0, this.brightness = 0.0, this.contrast = 0.0});

  /// Nothing changed: full filter, no brightness or contrast change.
  static const none = PageAdjustments();

  /// How much of the filter is applied: 0 = the original photo, 1 = the
  /// full filter. Ignored for [PageFilter.original].
  final double strength;

  /// -1 (much darker) … 0 … 1 (much brighter).
  final double brightness;

  /// -1 (flat) … 0 … 1 (punchy).
  final double contrast;

  bool get isNeutral => strength >= 1 && brightness == 0 && contrast == 0;

  PageAdjustments copyWith({double? strength, double? brightness, double? contrast}) => PageAdjustments(
        strength: strength ?? this.strength,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
      );

  @override
  bool operator ==(Object other) =>
      other is PageAdjustments &&
      other.strength == strength &&
      other.brightness == brightness &&
      other.contrast == contrast;

  @override
  int get hashCode => Object.hash(strength, brightness, contrast);
}

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
    this.adjustments = PageAdjustments.none,
    this.revision = 0,
  });

  final String id;

  /// Working copy inside the app's temp folder (never the user's original).
  final String imagePath;

  /// Clockwise rotation in 90° steps.
  final int quarterTurns;
  final PageFilter filter;

  /// Filter strength, brightness and contrast.
  final PageAdjustments adjustments;

  /// Bumped when the image file changes (e.g. after cropping) so image
  /// caches are refreshed.
  final int revision;

  DraftPage copyWith({
    String? imagePath,
    int? quarterTurns,
    PageFilter? filter,
    PageAdjustments? adjustments,
    int? revision,
  }) =>
      DraftPage(
        id: id,
        imagePath: imagePath ?? this.imagePath,
        quarterTurns: quarterTurns ?? this.quarterTurns,
        filter: filter ?? this.filter,
        adjustments: adjustments ?? this.adjustments,
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
    this.existingFolderId,
    this.existingIsFavorite = false,
    this.existingIsProtected = false,
    this.suggestedName,
  });

  /// Folder that holds this draft's working images.
  final String workDirPath;
  final List<DraftPage> pages;

  /// Set when editing a document that is already in the library; saving
  /// then replaces that document instead of creating a new one.
  final String? existingDocumentId;
  final String? existingName;
  final SaveFormat? existingFormat;
  final String? existingFolderId;
  final bool existingIsFavorite;

  /// The document being edited was saved with a PDF password.
  final bool existingIsProtected;

  /// Name offered in the save sheet for a new draft (e.g. a merge), when
  /// something better than the timestamp default is known.
  final String? suggestedName;

  DraftDocument copyWith({List<DraftPage>? pages}) => DraftDocument(
        workDirPath: workDirPath,
        pages: pages ?? this.pages,
        existingDocumentId: existingDocumentId,
        existingName: existingName,
        existingFormat: existingFormat,
        existingFolderId: existingFolderId,
        existingIsFavorite: existingIsFavorite,
        existingIsProtected: existingIsProtected,
        suggestedName: suggestedName,
      );
}
