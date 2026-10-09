import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../../settings/application/settings_controller.dart';

/// Choices made in the save sheet.
class SaveOptions {
  const SaveOptions({
    required this.name,
    required this.format,
    required this.quality,
    this.pageSize = PdfPageSize.auto,
    this.password,
    this.ocrLanguage,
  });

  final String name;
  final SaveFormat format;
  final ExportQuality quality;

  /// PDF only.
  final PdfPageSize pageSize;

  /// PDF only; null or empty = not protected.
  final String? password;

  /// PDF only; when set, the text is recognized while saving (searchable
  /// PDF). Null = no OCR.
  final OcrLanguage? ocrLanguage;
}

/// Shortest password accepted for a protected PDF.
const minPdfPasswordLength = 4;

/// Bottom sheet asking for file name, format (PDF/JPEG), quality, page size
/// and an optional PDF password. Returns null when dismissed.
///
/// [initialProtected] pre-selects password protection (when re-saving a
/// protected document); the password itself is never remembered.
Future<SaveOptions?> showSaveSheet(
  BuildContext context, {
  required String initialName,
  SaveFormat? initialFormat,
  bool initialProtected = false,
}) {
  return showModalBottomSheet<SaveOptions>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _SaveSheet(initialName: initialName, initialFormat: initialFormat, initialProtected: initialProtected),
  );
}

class _SaveSheet extends ConsumerStatefulWidget {
  const _SaveSheet({required this.initialName, this.initialFormat, this.initialProtected = false});

  final String initialName;
  final SaveFormat? initialFormat;
  final bool initialProtected;

  @override
  ConsumerState<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends ConsumerState<_SaveSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  final _password = TextEditingController();
  late SaveFormat _format;
  late ExportQuality _quality;
  late PdfPageSize _pageSize;
  late bool _searchable;
  late OcrLanguage _ocrLanguage;
  late bool _protect = widget.initialProtected;
  bool _showPassword = false;
  String? _error;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _format = widget.initialFormat ?? settings.defaultFormat;
    _quality = settings.defaultQuality;
    _pageSize = settings.defaultPageSize;
    _searchable = settings.searchablePdf;
    _ocrLanguage = settings.defaultOcrLanguage;
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    final password = _password.text;
    final protect = _protect && _format == SaveFormat.pdf;
    setState(() {
      _error = name.isEmpty ? l10n.fileNameEmpty : null;
      _passwordError = protect && password.length < minPdfPasswordLength ? l10n.passwordTooShort : null;
    });
    if (_error != null || _passwordError != null) return;
    Navigator.pop(
      context,
      SaveOptions(
        name: name,
        format: _format,
        quality: _quality,
        pageSize: _format == SaveFormat.pdf ? _pageSize : PdfPageSize.auto,
        password: protect ? password : null,
        ocrLanguage: _format == SaveFormat.pdf && _searchable ? _ocrLanguage : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isPdf = _format == SaveFormat.pdf;
    // The sheet reaches the bottom edge of the screen (useSafeArea only
    // insets the top), so keep the Save button above the system navigation
    // bar, or above the keyboard when it is open.
    final media = MediaQuery.of(context);
    final bottomInset = math.max(media.viewInsets.bottom, media.viewPadding.bottom);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
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
            if (isPdf) ...[
              const SizedBox(height: 20),
              Text(l10n.pageSize, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<PdfPageSize>(
                showSelectedIcon: false,
                segments: [
                  for (final s in PdfPageSize.values) ButtonSegment(value: s, label: Text(l10n.pageSizeLabel(s))),
                ],
                selected: {_pageSize},
                onSelectionChanged: (s) => setState(() => _pageSize = s.first),
              ),
              const SizedBox(height: 6),
              Text(l10n.pageSizeHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.manage_search),
                title: Text(l10n.searchablePdf),
                value: _searchable,
                onChanged: (v) => setState(() => _searchable = v),
              ),
              if (_searchable) ...[
                SegmentedButton<OcrLanguage>(
                  showSelectedIcon: false,
                  segments: [
                    for (final lang in OcrLanguage.values) ButtonSegment(value: lang, label: Text(l10n.ocrLanguageLabel(lang))),
                  ],
                  selected: {_ocrLanguage},
                  onSelectionChanged: (s) => setState(() => _ocrLanguage = s.first),
                ),
                const SizedBox(height: 6),
                Text(l10n.searchablePdfHint, style: theme.textTheme.bodySmall),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.lock_outline),
                title: Text(l10n.protectWithPassword),
                value: _protect,
                onChanged: (v) => setState(() => _protect = v),
              ),
              if (_protect) ...[
                TextField(
                  controller: _password,
                  obscureText: !_showPassword,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.pdfPassword,
                    errorText: _passwordError,
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 6),
                Text(l10n.passwordHint, style: theme.textTheme.bodySmall),
              ],
            ],
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.check), label: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
