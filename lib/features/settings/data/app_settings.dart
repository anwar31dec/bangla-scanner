import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';

/// User preferences. Immutable; update with [copyWith].
@immutable
class AppSettings {
  const AppSettings({
    this.languageCode = 'bn',
    this.themeMode = ThemeMode.system,
    this.defaultFormat = SaveFormat.pdf,
    this.defaultQuality = ExportQuality.medium,
    this.defaultPageSize = PdfPageSize.auto,
    this.defaultOcrLanguage = OcrLanguage.bangla,
    this.appLockEnabled = false,
    this.biometricUnlock = false,
    this.lockDelay = LockDelay.oneMinute,
  });

  /// 'bn' (default) or 'en'.
  final String languageCode;
  final ThemeMode themeMode;
  final SaveFormat defaultFormat;
  final ExportQuality defaultQuality;
  final PdfPageSize defaultPageSize;
  final OcrLanguage defaultOcrLanguage;

  /// The app asks for a PIN (see `SettingsRepository.pinHash`) on launch
  /// and after [lockDelay] in the background.
  final bool appLockEnabled;

  /// Offer fingerprint / face unlock on the lock screen as well.
  final bool biometricUnlock;
  final LockDelay lockDelay;

  Locale get locale => Locale(languageCode);

  AppSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    SaveFormat? defaultFormat,
    ExportQuality? defaultQuality,
    PdfPageSize? defaultPageSize,
    OcrLanguage? defaultOcrLanguage,
    bool? appLockEnabled,
    bool? biometricUnlock,
    LockDelay? lockDelay,
  }) =>
      AppSettings(
        languageCode: languageCode ?? this.languageCode,
        themeMode: themeMode ?? this.themeMode,
        defaultFormat: defaultFormat ?? this.defaultFormat,
        defaultQuality: defaultQuality ?? this.defaultQuality,
        defaultPageSize: defaultPageSize ?? this.defaultPageSize,
        defaultOcrLanguage: defaultOcrLanguage ?? this.defaultOcrLanguage,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        biometricUnlock: biometricUnlock ?? this.biometricUnlock,
        lockDelay: lockDelay ?? this.lockDelay,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.languageCode == languageCode &&
      other.themeMode == themeMode &&
      other.defaultFormat == defaultFormat &&
      other.defaultQuality == defaultQuality &&
      other.defaultPageSize == defaultPageSize &&
      other.defaultOcrLanguage == defaultOcrLanguage &&
      other.appLockEnabled == appLockEnabled &&
      other.biometricUnlock == biometricUnlock &&
      other.lockDelay == lockDelay;

  @override
  int get hashCode => Object.hash(
        languageCode,
        themeMode,
        defaultFormat,
        defaultQuality,
        defaultPageSize,
        defaultOcrLanguage,
        appLockEnabled,
        biometricUnlock,
        lockDelay,
      );
}
