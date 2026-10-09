import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/dialogs.dart';
import '../data/signature_store.dart';
import '../data/stamp_renderer.dart';
import 'signature_pad_screen.dart';

/// Opens the signature / stamp chooser. Returns the chosen image as a
/// transparent PNG, or null when dismissed.
Future<Uint8List?> showStampPicker(BuildContext context) {
  return showModalBottomSheet<Uint8List>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => const _StampPickerSheet(),
  );
}

/// Preset rubber-stamp texts.
enum _StampPreset { date, attested, trueCopy, originalSeen, paid, received }

class _StampPickerSheet extends ConsumerStatefulWidget {
  const _StampPickerSheet();

  @override
  ConsumerState<_StampPickerSheet> createState() => _StampPickerSheetState();
}

class _StampPickerSheetState extends ConsumerState<_StampPickerSheet> {
  StampColor _color = StampColor.blue;
  bool _busy = false;

  Future<void> _drawNew() async {
    final png = await Navigator.of(
      context,
    ).push<Uint8List>(MaterialPageRoute(fullscreenDialog: true, builder: (context) => const SignaturePadScreen()));
    if (png == null || !mounted) return;
    try {
      final store = await ref.read(signatureStoreProvider.future);
      await store.add(png);
      ref.invalidate(signaturesProvider);
    } catch (e) {
      if (mounted) showError(context, e);
      return;
    }
    if (mounted) Navigator.pop(context, png);
  }

  Future<void> _useSignature(File file) async {
    try {
      final png = await file.readAsBytes();
      if (mounted) Navigator.pop(context, png);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _deleteSignature(File file) async {
    final l10n = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l10n.deleteSignatureTitle,
      body: l10n.deleteSignatureBody,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      final store = await ref.read(signatureStoreProvider.future);
      await store.delete(file);
      ref.invalidate(signaturesProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  String _presetText(_StampPreset preset, AppLocalizations l10n) => switch (preset) {
    _StampPreset.date => Formatters.date(DateTime.now(), context.localeTag),
    _StampPreset.attested => l10n.stampAttested,
    _StampPreset.trueCopy => l10n.stampTrueCopy,
    _StampPreset.originalSeen => l10n.stampOriginalSeen,
    _StampPreset.paid => l10n.stampPaid,
    _StampPreset.received => l10n.stampReceived,
  };

  Future<void> _useText(String text, {bool border = true}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final png = await StampRenderer.renderText(text, color: _color, border: border);
      if (mounted) Navigator.pop(context, png);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _customText() async {
    final l10n = context.l10n;
    final text = await showTextInputDialog(
      context,
      title: l10n.stampCustomTitle,
      initialValue: '',
      label: l10n.stampText,
    );
    if (text == null || !mounted) return;
    await _useText(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final signatures = ref.watch(signaturesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(l10n.stampSheetTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(l10n.signatures, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _NewSignatureCard(onTap: _drawNew),
                for (final file in signatures.value ?? const <File>[])
                  _SignatureCard(
                    file: file,
                    onTap: () => _useSignature(file),
                    onLongPress: () => _deleteSignature(file),
                  ),
              ],
            ),
          ),
          if (signatures.hasValue && signatures.value!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.noSignatures, style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text(l10n.stamps, style: theme.textTheme.titleMedium)),
              for (final c in StampColor.values)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Semantics(
                    button: true,
                    selected: _color == c,
                    label: l10n.stampColorLabel(c),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == c ? theme.colorScheme.primary : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: _color == c ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _StampPreset.values)
                ActionChip(
                  avatar: preset == _StampPreset.date ? const Icon(Icons.calendar_today_outlined, size: 18) : null,
                  label: Text(
                    _presetText(preset, l10n),
                    style: TextStyle(color: _color.color, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _busy ? null : () => _useText(_presetText(preset, l10n)),
                ),
              ActionChip(
                avatar: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.stampCustom),
                onPressed: _busy ? null : _customText,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.stampBakeNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _NewSignatureCard extends StatelessWidget {
  const _NewSignatureCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.draw_outlined, color: scheme.onPrimaryContainer, size: 30),
                const SizedBox(height: 6),
                Text(
                  l10n.drawSignature,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({required this.file, required this.onTap, required this.onLongPress});

  final File file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Image.file(file, fit: BoxFit.contain, cacheWidth: 480),
          ),
        ),
      ),
    );
  }
}
