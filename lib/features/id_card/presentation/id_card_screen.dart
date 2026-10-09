import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/progress_overlay.dart';
import '../../export/data/export_service.dart';
import '../../export/presentation/save_sheet.dart';
import '../../scan/data/draft_document.dart';
import '../../scan/data/scanner_service.dart';
import '../../scan/presentation/scan_actions.dart';
import '../data/id_card_layout.dart';

/// Guided card flow: pick the document type (NID / smart card, passport),
/// scan the FRONT, then the BACK (optional for a passport), and both are
/// placed on one A4 page at real size and saved as PDF or JPEG.
class IdCardScreen extends ConsumerStatefulWidget {
  const IdCardScreen({super.key});

  @override
  ConsumerState<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends ConsumerState<IdCardScreen> {
  Directory? _workDir;
  CardKind _kind = CardKind.idCard;
  String? _front;
  String? _back;

  /// A side photographed upside down is shown and printed turned by 180°.
  bool _frontFlipped = false;
  bool _backFlipped = false;
  bool _busy = false;
  String? _progressText;

  /// 0 = front, 1 = back, 2 = ready.
  int get _step => _front == null ? 0 : (_back == null && _kind.needsBack ? 1 : 2);

  @override
  void dispose() {
    final dir = _workDir;
    if (dir != null) {
      dir.delete(recursive: true).ignore();
    }
    super.dispose();
  }

  Future<Directory> _ensureWorkDir() async {
    if (_workDir != null) return _workDir!;
    final paths = await ref.read(appPathsProvider.future);
    final dir = Directory(p.join(paths.workDir.path, 'idcard_${DateTime.now().microsecondsSinceEpoch}'));
    await dir.create(recursive: true);
    return _workDir = dir;
  }

  Future<void> _capture({required bool back, required bool fromGallery}) async {
    final paths = fromGallery
        ? await ScanActions.pickImages(context, ref, single: true)
        : await ScanActions.scanPages(context, ref, maxPages: 1);
    if (paths == null || paths.isEmpty) return;
    try {
      final dir = await _ensureWorkDir();
      final target = p.join(dir.path, '${back ? 'back' : 'front'}_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await File(paths.first).copy(target);
      setState(() {
        if (back) {
          _back = target;
          _backFlipped = false;
        } else {
          _front = target;
          _frontFlipped = false;
        }
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _createAndSave() async {
    final l10n = context.l10n;
    final front = _front, back = _back;
    if (front == null || (back == null && _kind.needsBack)) return;

    final options = await showSaveSheet(context, initialName: Formatters.defaultScanName(DateTime.now()));
    if (options == null || !mounted) return;

    setState(() {
      _busy = true;
      _progressText = l10n.saving;
    });
    try {
      final dir = await _ensureWorkDir();
      final sides = [await File(front).readAsBytes(), if (back != null) await File(back).readAsBytes()];
      final flipped = [_frontFlipped, if (back != null) _backFlipped];
      final pageBytes = await IdCardLayout.composeSidesInBackground(sides, kind: _kind, flipped: flipped);
      final pagePath = p.join(dir.path, 'a4_page.jpg');
      await File(pagePath).writeAsBytes(pageBytes, flush: true);

      final service = await ref.read(exportServiceProvider.future);
      final doc = await service.save(
        draft: DraftDocument(workDirPath: dir.path, pages: [DraftPage(id: 'idcard', imagePath: pagePath)]),
        name: options.name,
        format: options.format,
        quality: options.quality,
        pageSize: options.pageSize,
        password: options.password,
        ocrLanguage: options.ocrLanguage,
        onOcrProgress: (done, total) {
          if (mounted) setState(() => _progressText = done < total ? l10n.ocrRecognizing(done + 1, total) : l10n.saving);
        },
      );
      await ref.read(scannerServiceProvider).cleanCache();
      if (!mounted) return;
      showSnack(context, l10n.saved);
      context.pushReplacement(Routes.documentPath(doc.id));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final step = _step;
    final passport = _kind == CardKind.passport;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(l10n.idCardTitle)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.cardKind, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<CardKind>(
                  showSelectedIcon: false,
                  segments: [
                    for (final k in CardKind.values)
                      ButtonSegment(
                        value: k,
                        icon: Icon(k == CardKind.passport ? Icons.book_outlined : Icons.badge_outlined),
                        label: Text(l10n.cardKindLabel(k)),
                      ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: _busy ? null : (s) => setState(() => _kind = s.first),
                ),
              ),
              const SizedBox(height: 20),
              _StepHeader(step: step, backLabel: passport ? l10n.idCardOptional : l10n.idCardBack),
              const SizedBox(height: 16),
              Text(
                switch (step) {
                  0 => passport ? l10n.idCardHintPassport : l10n.idCardHintFront,
                  1 => l10n.idCardHintBack,
                  _ => passport ? l10n.idCardPassportReady : l10n.idCardReadyHint,
                },
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _CardSlot(
                label: passport ? l10n.cardKindPassport : l10n.idCardFront,
                aspectRatio: _kind.widthMm / _kind.heightMm,
                imagePath: _front,
                flipped: _frontFlipped,
                active: step == 0,
                onFlip: () => setState(() => _frontFlipped = !_frontFlipped),
                onScan: () => _capture(back: false, fromGallery: false),
                onGallery: () => _capture(back: false, fromGallery: true),
              ),
              const SizedBox(height: 16),
              _CardSlot(
                label: passport ? l10n.idCardPassportSecond : l10n.idCardBack,
                aspectRatio: _kind.widthMm / _kind.heightMm,
                imagePath: _back,
                flipped: _backFlipped,
                active: step == 1,
                onFlip: () => setState(() => _backFlipped = !_backFlipped),
                enabled: _front != null,
                onScan: () => _capture(back: true, fromGallery: false),
                onGallery: () => _capture(back: true, fromGallery: true),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: step == 2 && !_busy ? _createAndSave : null,
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.idCardCreate),
              ),
            ),
          ),
        ),
        if (_busy && _progressText != null) ProgressOverlay(message: _progressText!),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.backLabel});

  final int step;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget dot(int index, String label) {
      final done = step > index;
      final active = step == index;
      return Expanded(
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: done || active ? scheme.primary : scheme.surfaceContainerHighest,
              foregroundColor: done || active ? scheme.onPrimary : scheme.onSurfaceVariant,
              child: done ? const Icon(Icons.check, size: 20) : Text('${index + 1}'),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Row(children: [dot(0, l10n.idCardFront), dot(1, backLabel), dot(2, 'A4')]);
  }
}

class _CardSlot extends StatelessWidget {
  const _CardSlot({
    required this.label,
    required this.aspectRatio,
    required this.imagePath,
    required this.flipped,
    required this.active,
    required this.onFlip,
    required this.onScan,
    required this.onGallery,
    this.enabled = true,
  });

  final String label;
  final double aspectRatio;
  final String? imagePath;
  final bool flipped;
  final bool active;
  final bool enabled;
  final VoidCallback onFlip;
  final VoidCallback onScan;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasImage = imagePath != null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: active ? scheme.primary : Colors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            // Real card proportions.
            AspectRatio(
              aspectRatio: aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: hasImage
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            RotatedBox(
                              quarterTurns: flipped ? 2 : 0,
                              child: Image.file(File(imagePath!), fit: BoxFit.cover),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: IconButton.filledTonal(
                                  onPressed: onFlip,
                                  tooltip: l10n.rotate,
                                  icon: const Icon(Icons.rotate_right),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Icon(Icons.badge_outlined, size: 56, color: scheme.outline),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: enabled ? onScan : null,
                    icon: Icon(hasImage ? Icons.refresh : Icons.document_scanner_outlined),
                    label: Text(hasImage ? l10n.idCardRetake : l10n.idCardScan),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: enabled ? onGallery : null,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.idCardFromGallery, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
