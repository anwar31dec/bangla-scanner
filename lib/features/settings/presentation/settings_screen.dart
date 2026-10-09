import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_info.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/dialogs.dart';
import '../../lock/application/lock_controller.dart';
import '../../lock/presentation/lock_screen.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Asks for a new PIN twice; returns it, or null when cancelled or the
  /// two entries differ.
  static Future<String?> _askNewPin(BuildContext context) async {
    final l10n = context.l10n;
    final pin = await showPinDialog(context, title: l10n.setPinTitle, hint: l10n.setPinHint);
    if (pin == null || !context.mounted) return null;
    final again = await showPinDialog(context, title: l10n.confirmPinTitle);
    if (again == null || !context.mounted) return null;
    if (again != pin) {
      showSnack(context, l10n.pinMismatch);
      return null;
    }
    return pin;
  }

  /// Asks for the current PIN; true when it is right.
  static Future<bool> _confirmCurrentPin(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final pin = await showPinDialog(context, title: l10n.enterCurrentPin);
    if (pin == null || !context.mounted) return false;
    if (!ref.read(settingsProvider.notifier).verifyPin(pin)) {
      showSnack(context, l10n.wrongPin);
      return false;
    }
    return true;
  }

  static Future<void> _toggleLock(BuildContext context, WidgetRef ref, bool on) async {
    final l10n = context.l10n;
    final controller = ref.read(settingsProvider.notifier);
    if (on) {
      final pin = await _askNewPin(context);
      if (pin == null) return;
      await controller.enableAppLock(pin);
      if (context.mounted) showSnack(context, l10n.appLockOn);
    } else {
      if (!await _confirmCurrentPin(context, ref)) return;
      await controller.disableAppLock();
      if (context.mounted) showSnack(context, l10n.appLockOff);
    }
  }

  static Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    if (!await _confirmCurrentPin(context, ref)) return;
    if (!context.mounted) return;
    final pin = await _askNewPin(context);
    if (pin == null) return;
    await ref.read(settingsProvider.notifier).enableAppLock(pin);
    if (context.mounted) showSnack(context, context.l10n.appLockOn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final biometricsAvailable = ref.watch(biometricsAvailableProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Section(
            icon: Icons.translate,
            title: l10n.settingsLanguage,
            child: _Choice<String>(
              selected: settings.languageCode,
              options: const {'bn': 'বাংলা', 'en': 'English'},
              onChanged: controller.setLanguage,
            ),
          ),
          _Section(
            icon: Icons.brightness_6_outlined,
            title: l10n.settingsTheme,
            child: _Choice<ThemeMode>(
              selected: settings.themeMode,
              options: {
                ThemeMode.light: l10n.themeLight,
                ThemeMode.dark: l10n.themeDark,
                ThemeMode.system: l10n.themeSystem,
              },
              onChanged: controller.setThemeMode,
            ),
          ),
          _Section(
            icon: Icons.save_outlined,
            title: l10n.settingsDefaultFormat,
            child: _Choice<SaveFormat>(
              selected: settings.defaultFormat,
              options: {for (final f in SaveFormat.values) f: l10n.formatLabel(f)},
              onChanged: controller.setDefaultFormat,
            ),
          ),
          _Section(
            icon: Icons.high_quality_outlined,
            title: l10n.settingsDefaultQuality,
            child: _Choice<ExportQuality>(
              selected: settings.defaultQuality,
              options: {for (final q in ExportQuality.values) q: l10n.qualityLabel(q)},
              onChanged: controller.setDefaultQuality,
            ),
          ),
          _Section(
            icon: Icons.crop_portrait,
            title: l10n.settingsDefaultPageSize,
            child: _Choice<PdfPageSize>(
              selected: settings.defaultPageSize,
              options: {for (final s in PdfPageSize.values) s: l10n.pageSizeLabel(s)},
              onChanged: controller.setDefaultPageSize,
            ),
          ),
          _Section(
            icon: Icons.text_fields,
            title: l10n.settingsDefaultOcr,
            child: _Choice<OcrLanguage>(
              selected: settings.defaultOcrLanguage,
              options: {for (final o in OcrLanguage.values) o: l10n.ocrLanguageLabel(o)},
              onChanged: controller.setDefaultOcrLanguage,
            ),
          ),
          _Section(
            icon: Icons.manage_search,
            title: l10n.settingsSearchablePdf,
            child: Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.text_snippet_outlined),
                title: Text(l10n.searchablePdf),
                subtitle: Text(l10n.settingsSearchablePdfHint),
                value: settings.searchablePdf,
                onChanged: controller.setSearchablePdf,
              ),
            ),
          ),
          _Section(
            icon: Icons.lock_outline,
            title: l10n.settingsAppLock,
            child: Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.pin_outlined),
                    title: Text(l10n.appLockEnable),
                    value: settings.appLockEnabled,
                    onChanged: (on) => _toggleLock(context, ref, on),
                  ),
                  if (settings.appLockEnabled) ...[
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint),
                      title: Text(l10n.appLockBiometric),
                      subtitle: biometricsAvailable ? null : Text(l10n.biometricUnavailable),
                      value: settings.biometricUnlock && biometricsAvailable,
                      onChanged: biometricsAvailable ? controller.setBiometricUnlock : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: Text(l10n.appLockDelay),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _Choice<LockDelay>(
                          selected: settings.lockDelay,
                          options: {for (final d in LockDelay.values) d: l10n.lockDelayLabel(d)},
                          onChanged: controller.setLockDelay,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.password_outlined),
                      title: Text(l10n.changePin),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _changePin(context, ref),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _Section(
            icon: Icons.cloud_off_outlined,
            title: l10n.settingsBackup,
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: Text(l10n.backupTitle),
                subtitle: Text(l10n.backupSettingsHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.backup),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsAbout),
              subtitle: Text('${l10n.settingsOffline}\n${l10n.settingsVersion(appVersion)}'),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Full-width segmented choice with large tap targets.
class _Choice<T> extends StatelessWidget {
  const _Choice({required this.selected, required this.options, required this.onChanged});

  final T selected;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final e in options.entries) ButtonSegment<T>(value: e.key, label: Text(e.value)),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
