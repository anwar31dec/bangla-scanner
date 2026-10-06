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
  Future<void> setDefaultOcrLanguage(OcrLanguage l) => _update(state.copyWith(defaultOcrLanguage: l));
}
