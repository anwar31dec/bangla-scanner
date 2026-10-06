import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../application/library_providers.dart';
import 'document_actions.dart';

/// Opens a saved document: swipe through pages, share, save to phone,
/// extract text, edit, rename or delete.
class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

enum _MenuAction { rename, edit, delete }

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  final _pageController = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onMenu(_MenuAction action, DocumentRow doc) async {
    switch (action) {
      case _MenuAction.rename:
        await DocumentActions.rename(context, ref, doc);
      case _MenuAction.edit:
        await DocumentActions.edit(context, ref, doc);
      case _MenuAction.delete:
        if (await DocumentActions.delete(context, ref, doc) && mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final docAsync = ref.watch(documentProvider(widget.documentId));
    final doc = docAsync.value;

    if (docAsync.isLoading && doc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: EmptyState(icon: Icons.error_outline, title: l10n.documentMissing)),
      );
    }

    final pagesAsync = ref.watch(documentPagesProvider(doc.id));
    final pages = pagesAsync.value ?? const <File>[];
    final locale = context.localeTag;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.name, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (a) => _onMenu(a, doc),
            itemBuilder: (context) => [
              PopupMenuItem(value: _MenuAction.rename, child: ListTile(leading: const Icon(Icons.drive_file_rename_outline), title: Text(l10n.rename))),
              PopupMenuItem(value: _MenuAction.edit, child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l10n.edit))),
              PopupMenuItem(value: _MenuAction.delete, child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(l10n.delete))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              [
                l10n.formatLabel(doc.format),
                l10n.editorPages(doc.pageCount),
                Formatters.fileSize(doc.sizeBytes, locale),
                Formatters.dateTime(doc.createdAt, locale),
              ].join('  ·  '),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: pagesAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pages.isEmpty
                    ? Center(child: EmptyState(icon: Icons.broken_image_outlined, title: l10n.documentMissing))
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: pages.length,
                        onPageChanged: (i) => setState(() => _current = i),
                        itemBuilder: (context, i) => InteractiveViewer(
                          maxScale: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.file(
                              pages[i],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) =>
                                  Center(child: EmptyState(icon: Icons.broken_image_outlined, title: l10n.errorCorruptFile)),
                            ),
                          ),
                        ),
                      ),
          ),
          if (pages.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l10n.pageEditTitle(_current + 1, pages.length), style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) => FilledButton.icon(
                    onPressed: () => DocumentActions.share(context, ref, doc),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(l10n.share),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => DocumentActions.saveToDevice(context, ref, doc),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.saveToDevice, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
