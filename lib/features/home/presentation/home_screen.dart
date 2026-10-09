import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/empty_state.dart';
import '../../library/application/library_providers.dart';
import '../../library/presentation/document_tile.dart';
import '../../scan/presentation/scan_actions.dart';

/// Home: one big Scan button, Flash Scan, Import and ID Card shortcuts, then
/// recent documents.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recent = ref.watch(recentDocumentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.navLibrary,
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => context.push(Routes.library),
          ),
          IconButton(
            tooltip: l10n.navSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverList.list(
              children: [
                Text(l10n.homeGreeting, style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                ScanHeroButton(onPressed: () => ScanActions.scanNew(context, ref)),
                const SizedBox(height: 12),
                FlashScanTile(onPressed: () => ScanActions.flashScanNew(context, ref)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: HomeActionTile(
                        icon: Icons.file_download_outlined,
                        label: l10n.homeImport,
                        onPressed: () => ScanActions.importNew(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HomeActionTile(
                        icon: Icons.badge_outlined,
                        label: l10n.homeIdCard,
                        onPressed: () => context.push(Routes.idCard),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: Text(l10n.homeRecent, style: theme.textTheme.titleLarge)),
                    if (recent.value?.isNotEmpty ?? false)
                      TextButton(onPressed: () => context.push(Routes.library), child: Text(l10n.homeSeeAll)),
                  ],
                ),
              ],
            ),
          ),
          ...recent.when(
            loading: () => [const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))],
            error: (e, _) => [SliverToBoxAdapter(child: EmptyState(icon: Icons.error_outline, title: l10n.errorGeneric))],
            data: (docs) => docs.isEmpty
                ? [
                    SliverToBoxAdapter(
                      child: EmptyState(icon: Icons.description_outlined, title: l10n.homeEmpty, message: l10n.homeEmptyHint),
                    ),
                  ]
                : [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: docs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => DocumentTile(key: ValueKey(docs[i].id), doc: docs[i]),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

/// The large primary "Scan" button.
class ScanHeroButton extends StatelessWidget {
  const ScanHeroButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: l10n.homeScan,
      child: Material(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: scheme.onPrimary.withValues(alpha: 0.15),
                  child: Icon(Icons.document_scanner_outlined, size: 38, color: scheme.onPrimary),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeScan,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.homeScanSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wide secondary action below the Scan button: the in-app camera whose
/// flash fires only when a photo is taken.
class FlashScanTile extends StatelessWidget {
  const FlashScanTile({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.flash_on_outlined, size: 32, color: scheme.onSecondaryContainer),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeFlashScan,
                      style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                    Text(
                      l10n.homeFlashScanSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary square-ish action (Import, ID Card).
class HomeActionTile extends StatelessWidget {
  const HomeActionTile({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
