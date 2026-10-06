import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/widgets/dialogs.dart';
import '../../export/data/share_service.dart';
import '../../library/application/library_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../application/ocr_controller.dart';

/// Extract text from a saved document: choose the language, watch the
/// progress, then edit / copy / share / save the result.
class OcrScreen extends ConsumerStatefulWidget {
  const OcrScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends ConsumerState<OcrScreen> {
  late OcrLanguage _language = ref.read(settingsProvider).defaultOcrLanguage;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final pages = await ref.read(documentPagesProvider(widget.documentId).future);
    if (!mounted) return;
    if (pages.isEmpty) {
      showSnack(context, context.l10n.documentMissing);
      return;
    }
    await ref.read(ocrControllerProvider.notifier).run([for (final f in pages) f.path], _language);
  }

  String _docName() => ref.read(documentProvider(widget.documentId)).value?.name ?? 'Text';

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text.text));
    if (mounted) showSnack(context, context.l10n.copied);
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      final service = await ref.read(shareServiceProvider.future);
      await service.shareText(_text.text, subject: _docName(), origin: origin);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _saveTxt() async {
    final l10n = context.l10n;
    if (!await PermissionService.ensureStorageForDownloads(context)) return;
    try {
      final service = await ref.read(shareServiceProvider.future);
      final result = await service.saveTextToDevice(_text.text, _docName());
      if (!mounted) return;
      if (result == SaveDestination.downloads) showSnack(context, l10n.savedToDownloads);
      if (result == SaveDestination.files) showSnack(context, l10n.savedToFiles);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(ocrControllerProvider);

    // Fill the editor once when recognition finishes.
    ref.listen(ocrControllerProvider, (prev, next) {
      if (next.stage == OcrStage.done && prev?.stage != OcrStage.done) _text.text = next.text;
    });

    final showResult = state.stage == OcrStage.done && state.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(showResult ? l10n.ocrResultTitle : l10n.ocrTitle)),
      body: SafeArea(child: showResult ? _buildResult(context) : _buildSetup(context, state)),
    );
  }

  Widget _buildSetup(BuildContext context, OcrState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final running = state.isRunning;

    String statusText() => switch (state.stage) {
          OcrStage.preparing => l10n.ocrPreparing,
          OcrStage.preprocessing => l10n.ocrPreprocessing(state.current, state.total),
          OcrStage.recognizing => l10n.ocrRecognizing(state.current, state.total),
          _ => '',
        };

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(l10n.ocrLanguage, style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        SegmentedButton<OcrLanguage>(
          showSelectedIcon: false,
          segments: [
            for (final lang in OcrLanguage.values) ButtonSegment(value: lang, label: Text(l10n.ocrLanguageLabel(lang))),
          ],
          selected: {_language},
          onSelectionChanged: running ? null : (s) => setState(() => _language = s.first),
        ),
        const SizedBox(height: 28),
        if (running) ...[
          LinearProgressIndicator(value: state.progress, minHeight: 10, borderRadius: BorderRadius.circular(5)),
          const SizedBox(height: 14),
          Text(statusText(), style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
        ] else ...[
          if (state.stage == OcrStage.failed)
            _Message(icon: Icons.error_outline, text: state.error?.message(l10n) ?? l10n.ocrFailed, color: theme.colorScheme.error),
          if (state.stage == OcrStage.done && state.text.isEmpty)
            _Message(icon: Icons.text_fields, text: l10n.ocrNoText, color: theme.colorScheme.onSurfaceVariant),
          FilledButton.icon(
            onPressed: _start,
            icon: Icon(state.stage == OcrStage.idle ? Icons.text_snippet_outlined : Icons.refresh),
            label: Text(state.stage == OcrStage.idle ? l10n.ocrStart : l10n.retry),
          ),
        ],
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(l10n.ocrHint, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _text,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _copy, icon: const Icon(Icons.copy), label: Text(l10n.copy))),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(
                  builder: (buttonContext) => FilledButton.icon(
                    onPressed: () => _share(buttonContext),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(l10n.share),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveTxt,
                  icon: const Icon(Icons.save_alt),
                  label: Text(l10n.saveTxt, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
