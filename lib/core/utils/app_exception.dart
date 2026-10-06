import 'dart:io';

import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';

/// Kinds of failures the UI knows how to explain to the user.
enum AppErrorKind { lowStorage, corruptFile, missingFile, ocrFailed, generic }

/// An error with a user friendly, localized explanation.
class AppException implements Exception {
  const AppException(this.kind, [this.cause]);

  final AppErrorKind kind;
  final Object? cause;

  /// Maps any error to an [AppException] so screens can show a clear message.
  factory AppException.from(Object error) {
    if (error is AppException) return error;
    if (error is FileSystemException) {
      // errno 28 = ENOSPC (no space left on device) on Android and iOS.
      final code = error.osError?.errorCode;
      if (code == 28) return AppException(AppErrorKind.lowStorage, error);
      if (code == 2) return AppException(AppErrorKind.missingFile, error);
    }
    if (error is PlatformException &&
        (error.message?.toLowerCase().contains('no space') ?? false)) {
      return AppException(AppErrorKind.lowStorage, error);
    }
    return AppException(AppErrorKind.generic, error);
  }

  String message(AppLocalizations l10n) => switch (kind) {
        AppErrorKind.lowStorage => l10n.errorLowStorage,
        AppErrorKind.corruptFile => l10n.errorCorruptFile,
        AppErrorKind.missingFile => l10n.documentMissing,
        AppErrorKind.ocrFailed => l10n.ocrFailed,
        AppErrorKind.generic => l10n.errorGeneric,
      };

  @override
  String toString() => 'AppException($kind, $cause)';
}
