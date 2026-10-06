import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/enums.dart';
import 'app_settings.dart';

/// Persists [AppSettings] in SharedPreferences.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kLanguage = 'settings.language';
  static const _kTheme = 'settings.theme';
  static const _kFormat = 'settings.format';
  static const _kQuality = 'settings.quality';
  static const _kOcr = 'settings.ocrLanguage';

  AppSettings load() {
    const defaults = AppSettings();
    final language = _prefs.getString(_kLanguage);
    return AppSettings(
      languageCode: language == 'en' ? 'en' : 'bn',
      themeMode: _byName(ThemeMode.values, _prefs.getString(_kTheme), defaults.themeMode),
      defaultFormat: _byName(SaveFormat.values, _prefs.getString(_kFormat), defaults.defaultFormat),
      defaultQuality: _byName(ExportQuality.values, _prefs.getString(_kQuality), defaults.defaultQuality),
      defaultOcrLanguage: _byName(OcrLanguage.values, _prefs.getString(_kOcr), defaults.defaultOcrLanguage),
    );
  }

  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setString(_kLanguage, s.languageCode),
      _prefs.setString(_kTheme, s.themeMode.name),
      _prefs.setString(_kFormat, s.defaultFormat.name),
      _prefs.setString(_kQuality, s.defaultQuality.name),
      _prefs.setString(_kOcr, s.defaultOcrLanguage.name),
    ]);
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
