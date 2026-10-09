import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/lock/application/lock_controller.dart';
import 'features/lock/presentation/lock_screen.dart';
import 'features/settings/application/settings_controller.dart';

class BanglaScannerApp extends ConsumerWidget {
  const BanglaScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) => LockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Puts the lock screen over the whole app while it is locked. The app
/// underneath keeps its state, so unlocking returns exactly where the user
/// was.
class LockGate extends ConsumerWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = ref.watch(lockControllerProvider);
    if (!locked) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(child: ExcludeSemantics(child: child)),
        const LockScreen(),
      ],
    );
  }
}
