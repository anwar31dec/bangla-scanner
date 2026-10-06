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
    this.defaultOcrLanguage = OcrLanguage.bangla,
  });

  /// 'bn' (default) or 'en'.
  final String languageCode;
  final ThemeMode themeMode;
  final SaveFormat defaultFormat;
  final ExportQuality defaultQuality;
  final OcrLanguage defaultOcrLanguage;

  Locale get locale => Locale(languageCode);

  AppSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    SaveFormat? defaultFormat,
    ExportQuality? defaultQuality,
    OcrLanguage? defaultOcrLanguage,
  }) =>
      AppSettings(
        languageCode: languageCode ?? this.languageCode,
        themeMode: themeMode ?? this.themeMode,
        defaultFormat: defaultFormat ?? this.defaultFormat,
        defaultQuality: defaultQuality ?? this.defaultQuality,
        defaultOcrLanguage: defaultOcrLanguage ?? this.defaultOcrLanguage,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.languageCode == languageCode &&
      other.themeMode == themeMode &&
      other.defaultFormat == defaultFormat &&
      other.defaultQuality == defaultQuality &&
      other.defaultOcrLanguage == defaultOcrLanguage;

  @override
  int get hashCode => Object.hash(languageCode, themeMode, defaultFormat, defaultQuality, defaultOcrLanguage);
}
