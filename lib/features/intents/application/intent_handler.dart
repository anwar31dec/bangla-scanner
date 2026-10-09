import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../lock/application/lock_controller.dart';
import '../../scan/presentation/scan_actions.dart';
import '../../settings/application/settings_controller.dart';
import '../data/received_files_channel.dart';

/// Home screen quick actions (long-press the app icon).
abstract final class QuickActionTypes {
  static const scan = 'scan';
  static const flashScan = 'flash_scan';
}

/// Reacts to things that reach the app from outside the widget tree: files
/// shared or opened from other apps, and home screen quick actions.
///
/// Sits in `MaterialApp.builder`, so it exists for the whole app lifetime
/// and has a [WidgetRef]. UI work (dialogs, navigation) runs with the root
/// navigator's overlay context. While the app lock is showing, requests
/// wait until the user has unlocked, so nothing opens behind the lock.
class IntentHandler extends ConsumerStatefulWidget {
  const IntentHandler({super.key, required this.child, this.quickActions});

  final Widget child;

  /// Replaced in tests.
  final QuickActions? quickActions;

  @override
  ConsumerState<IntentHandler> createState() => _IntentHandlerState();
}

class _IntentHandlerState extends ConsumerState<IntentHandler> {
  StreamSubscription<List<String>>? _files;
  final _pending = <Future<void> Function(BuildContext context)>[];
  bool _running = false;
  String? _shortcutsLanguage;

  @override
  void initState() {
    super.initState();
    final channel = ref.read(receivedFilesChannelProvider);
    _files = channel.files.listen(_onFiles);
    // Launch intents are read once the first frame exists.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await channel.takeInitialFiles();
      if (initial.isNotEmpty) _onFiles(initial);
    });
    _initQuickActions();
  }

  @override
  void dispose() {
    _files?.cancel();
    super.dispose();
  }

  Future<void> _initQuickActions() async {
    final actions = widget.quickActions ?? const QuickActions();
    try {
      await actions.initialize((type) {
        switch (type) {
          case QuickActionTypes.scan:
            _enqueue((context) => ScanActions.scanNew(context, ref));
          case QuickActionTypes.flashScan:
            _enqueue((context) => ScanActions.flashScanNew(context, ref));
        }
      });
    } catch (_) {
      // Not available on this platform (or in tests).
    }
  }

  /// (Re)registers the shortcuts in the current UI language.
  Future<void> _updateShortcuts(String language, AppLocalizations l10n) async {
    if (_shortcutsLanguage == language) return;
    _shortcutsLanguage = language;
    final actions = widget.quickActions ?? const QuickActions();
    try {
      await actions.setShortcutItems([
        ShortcutItem(type: QuickActionTypes.scan, localizedTitle: l10n.homeScan, icon: 'ic_shortcut_scan'),
        ShortcutItem(type: QuickActionTypes.flashScan, localizedTitle: l10n.homeFlashScan, icon: 'ic_shortcut_flash'),
      ]);
    } catch (_) {}
  }

  void _onFiles(List<String> paths) => _enqueue((context) => ScanActions.importReceived(context, ref, paths));

  void _enqueue(Future<void> Function(BuildContext context) action) {
    _pending.add(action);
    _drain();
  }

  Future<void> _drain() async {
    if (_running || _pending.isEmpty) return;
    if (ref.read(lockControllerProvider)) return; // resumed by the lock listener
    if (rootNavigatorKey.currentState?.overlay == null) {
      // The navigator is not built yet; try again after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _drain());
      return;
    }
    _running = true;
    try {
      while (_pending.isNotEmpty && !ref.read(lockControllerProvider)) {
        final action = _pending.removeAt(0);
        // The overlay outlives every route; a fresh lookup each round.
        final overlayContext = rootNavigatorKey.currentState?.overlay?.context;
        if (overlayContext == null || !overlayContext.mounted) return;
        // Dialogs and pushes belong on top of Home, not on top of whatever
        // was open (the lock screen aside).
        GoRouter.of(overlayContext).go(Routes.home);
        await action(overlayContext);
      }
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lockControllerProvider, (previous, locked) {
      if (!locked) _drain();
    });
    final language = ref.watch(settingsProvider.select((s) => s.languageCode));
    // The shortcut titles follow the app language; the lookup needs a
    // context under MaterialApp, which `builder` gives us.
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (l10n != null) _updateShortcuts(language, l10n);
    return widget.child;
  }
}
