import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/enums.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../data/document_repository.dart';
import 'document_actions.dart';

enum _TileAction { share, rename, delete }

/// A document row: thumbnail, name, page count, date and size, with a menu
/// for share / rename / delete.
///
/// When [selectionOrder] is given the tile is in multi-select mode: the
/// menu is replaced by a check mark (numbered with the selection order, or
/// empty when not selected) and taps/long-presses go to [onToggle].
class DocumentTile extends ConsumerWidget {
  const DocumentTile({
    super.key,
    required this.doc,
    this.selecting = false,
    this.selectionOrder,
    this.onToggle,
    this.onLongPress,
  });

  final DocumentRow doc;

  /// True while the list is in multi-select mode.
  final bool selecting;

  /// 1-based position of this document in the selection, or null when it is
  /// not selected.
  final int? selectionOrder;

  /// Called on tap while [selecting].
  final VoidCallback? onToggle;

  /// Called on long press when not [selecting] (starts selection).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.localeTag;
    final repo = ref.watch(documentRepositoryProvider).value;
    final selected = selectionOrder != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            )
          : null,
      color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
      child: InkWell(
        onTap: selecting ? onToggle : () => context.push(Routes.documentPath(doc.id)),
        onLongPress: selecting ? onToggle : onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 74,
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: repo == null
                        ? null
                        : Image.file(
                            repo.thumbnailOf(doc),
                            key: ValueKey('${doc.id}-${doc.updatedAt.millisecondsSinceEpoch}'),
                            fit: BoxFit.cover,
                            cacheWidth: 168,
                            errorBuilder: (context, error, stack) => const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          doc.format == SaveFormat.pdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${l10n.editorPages(doc.pageCount)} · ${Formatters.fileSize(doc.sizeBytes, locale)}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(Formatters.date(doc.createdAt, locale), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (selecting)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: selected
                      ? CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          child: Text('$selectionOrder', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                        )
                      : Icon(Icons.radio_button_unchecked, color: theme.colorScheme.outline, size: 28),
                )
              else
                PopupMenuButton<_TileAction>(
                  tooltip: '',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    switch (action) {
                      case _TileAction.share:
                        DocumentActions.share(context, ref, doc);
                      case _TileAction.rename:
                        DocumentActions.rename(context, ref, doc);
                      case _TileAction.delete:
                        DocumentActions.delete(context, ref, doc);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: _TileAction.share, child: ListTile(leading: const Icon(Icons.share_outlined), title: Text(l10n.share))),
                    PopupMenuItem(value: _TileAction.rename, child: ListTile(leading: const Icon(Icons.drive_file_rename_outline), title: Text(l10n.rename))),
                    PopupMenuItem(value: _TileAction.delete, child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(l10n.delete))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
