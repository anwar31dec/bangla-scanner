import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../../settings/application/settings_controller.dart';

/// Choices made in the save sheet.
class SaveOptions {
  const SaveOptions({required this.name, required this.format, required this.quality});

  final String name;
  final SaveFormat format;
  final ExportQuality quality;
}

/// Bottom sheet asking for file name, format (PDF/JPEG) and quality.
/// Returns null when dismissed.
Future<SaveOptions?> showSaveSheet(
  BuildContext context, {
  required String initialName,
  SaveFormat? initialFormat,
}) {
  return showModalBottomSheet<SaveOptions>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _SaveSheet(initialName: initialName, initialFormat: initialFormat),
  );
}

class _SaveSheet extends ConsumerStatefulWidget {
  const _SaveSheet({required this.initialName, this.initialFormat});

  final String initialName;
  final SaveFormat? initialFormat;

  @override
  ConsumerState<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends ConsumerState<_SaveSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  late SaveFormat _format;
  late ExportQuality _quality;
  String? _error;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _format = widget.initialFormat ?? settings.defaultFormat;
    _quality = settings.defaultQuality;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.fileNameEmpty);
      return;
    }
    Navigator.pop(context, SaveOptions(name: name, format: _format, quality: _quality));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.saveTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              maxLength: 80,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.fileName,
                errorText: _error,
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Text(l10n.format, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<SaveFormat>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: SaveFormat.pdf, icon: const Icon(Icons.picture_as_pdf_outlined), label: Text(l10n.formatPdf)),
                ButtonSegment(value: SaveFormat.jpeg, icon: const Icon(Icons.image_outlined), label: Text(l10n.formatJpeg)),
              ],
              selected: {_format},
              onSelectionChanged: (s) => setState(() => _format = s.first),
            ),
            const SizedBox(height: 20),
            Text(l10n.quality, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ExportQuality>(
              showSelectedIcon: false,
              segments: [
                for (final q in ExportQuality.values) ButtonSegment(value: q, label: Text(l10n.qualityLabel(q))),
              ],
              selected: {_quality},
              onSelectionChanged: (s) => setState(() => _quality = s.first),
            ),
            const SizedBox(height: 6),
            Text(l10n.qualityHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.check), label: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
