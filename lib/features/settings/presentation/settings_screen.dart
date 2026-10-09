import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../application/settings_controller.dart';

const appVersion = '1.0.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

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
            icon: Icons.text_fields,
            title: l10n.settingsDefaultOcr,
            child: _Choice<OcrLanguage>(
              selected: settings.defaultOcrLanguage,
              options: {for (final o in OcrLanguage.values) o: l10n.ocrLanguageLabel(o)},
              onChanged: controller.setDefaultOcrLanguage,
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
