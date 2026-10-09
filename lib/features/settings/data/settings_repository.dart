import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/enums.dart';
import 'app_settings.dart';

/// Persists [AppSettings] in SharedPreferences, plus the app-lock PIN as a
/// salted hash (the PIN itself is never stored).
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kLanguage = 'settings.language';
  static const _kTheme = 'settings.theme';
  static const _kFormat = 'settings.format';
  static const _kQuality = 'settings.quality';
  static const _kPageSize = 'settings.pageSize';
  static const _kOcr = 'settings.ocrLanguage';
  static const _kLockEnabled = 'settings.lock.enabled';
  static const _kLockBiometric = 'settings.lock.biometric';
  static const _kLockDelay = 'settings.lock.delay';
  static const _kPinSalt = 'settings.lock.pinSalt';
  static const _kPinHash = 'settings.lock.pinHash';

  AppSettings load() {
    const defaults = AppSettings();
    final language = _prefs.getString(_kLanguage);
    return AppSettings(
      languageCode: language == 'en' ? 'en' : 'bn',
      themeMode: _byName(ThemeMode.values, _prefs.getString(_kTheme), defaults.themeMode),
      defaultFormat: _byName(SaveFormat.values, _prefs.getString(_kFormat), defaults.defaultFormat),
      defaultQuality: _byName(ExportQuality.values, _prefs.getString(_kQuality), defaults.defaultQuality),
      defaultPageSize: _byName(PdfPageSize.values, _prefs.getString(_kPageSize), defaults.defaultPageSize),
      defaultOcrLanguage: _byName(OcrLanguage.values, _prefs.getString(_kOcr), defaults.defaultOcrLanguage),
      // A lock without a PIN would lock the user out for good.
      appLockEnabled: (_prefs.getBool(_kLockEnabled) ?? false) && hasPin,
      biometricUnlock: _prefs.getBool(_kLockBiometric) ?? false,
      lockDelay: _byName(LockDelay.values, _prefs.getString(_kLockDelay), defaults.lockDelay),
    );
  }

  Future<void> save(AppSettings s) async {
    await Future.wait([
      _prefs.setString(_kLanguage, s.languageCode),
      _prefs.setString(_kTheme, s.themeMode.name),
      _prefs.setString(_kFormat, s.defaultFormat.name),
      _prefs.setString(_kQuality, s.defaultQuality.name),
      _prefs.setString(_kPageSize, s.defaultPageSize.name),
      _prefs.setString(_kOcr, s.defaultOcrLanguage.name),
      _prefs.setBool(_kLockEnabled, s.appLockEnabled),
      _prefs.setBool(_kLockBiometric, s.biometricUnlock),
      _prefs.setString(_kLockDelay, s.lockDelay.name),
    ]);
  }

  // PIN ---------------------------------------------------------------------

  bool get hasPin => _prefs.getString(_kPinHash) != null && _prefs.getString(_kPinSalt) != null;

  /// Stores a fresh salted SHA-256 of [pin].
  Future<void> setPin(String pin) async {
    final random = Random.secure();
    final salt = base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
    await _prefs.setString(_kPinSalt, salt);
    await _prefs.setString(_kPinHash, _hash(pin, salt));
  }

  Future<void> clearPin() async {
    await _prefs.remove(_kPinSalt);
    await _prefs.remove(_kPinHash);
  }

  bool verifyPin(String pin) {
    final salt = _prefs.getString(_kPinSalt), hash = _prefs.getString(_kPinHash);
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }

  static String _hash(String pin, String salt) {
    // A few thousand rounds make guessing on a copied prefs file slower.
    var digest = sha256.convert(utf8.encode('$salt:$pin')).bytes;
    for (var i = 0; i < 5000; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64Encode(digest);
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
