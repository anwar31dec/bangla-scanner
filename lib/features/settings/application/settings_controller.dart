import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/enums.dart';
import '../data/app_settings.dart';
import '../data/settings_repository.dart';

/// Overridden in `main()` with an already-loaded instance so settings are
/// available synchronously on the first frame (no language/theme flicker).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setLanguage(String code) => _update(state.copyWith(languageCode: code));
  Future<void> setThemeMode(ThemeMode mode) => _update(state.copyWith(themeMode: mode));
  Future<void> setDefaultFormat(SaveFormat f) => _update(state.copyWith(defaultFormat: f));
  Future<void> setDefaultQuality(ExportQuality q) => _update(state.copyWith(defaultQuality: q));
  Future<void> setDefaultPageSize(PdfPageSize s) => _update(state.copyWith(defaultPageSize: s));
  Future<void> setDefaultOcrLanguage(OcrLanguage l) => _update(state.copyWith(defaultOcrLanguage: l));
  Future<void> setSearchablePdf(bool on) => _update(state.copyWith(searchablePdf: on));
  Future<void> setBiometricUnlock(bool on) => _update(state.copyWith(biometricUnlock: on));
  Future<void> setLockDelay(LockDelay d) => _update(state.copyWith(lockDelay: d));

  /// Turns the app lock on with [pin] (also used to change the PIN).
  Future<void> enableAppLock(String pin) async {
    await ref.read(settingsRepositoryProvider).setPin(pin);
    await _update(state.copyWith(appLockEnabled: true));
  }

  Future<void> disableAppLock() async {
    await _update(state.copyWith(appLockEnabled: false, biometricUnlock: false));
    await ref.read(settingsRepositoryProvider).clearPin();
  }

  bool verifyPin(String pin) => ref.read(settingsRepositoryProvider).verifyPin(pin);
}
