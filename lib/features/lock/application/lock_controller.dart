import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../settings/application/settings_controller.dart';

/// True while the lock screen must cover the app.
final lockControllerProvider = NotifierProvider<LockController, bool>(LockController.new);

/// Whether this phone can do fingerprint / face unlock at all.
final biometricsAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    final auth = LocalAuthentication();
    return await auth.isDeviceSupported() && await auth.canCheckBiometrics;
  } catch (_) {
    return false;
  }
});

/// Locks the app on launch and after it has been in the background longer
/// than the chosen delay. Unlocked with the PIN or biometrics.
class LockController extends Notifier<bool> with WidgetsBindingObserver {
  DateTime? _backgroundSince;

  /// A biometric prompt moves the app to the background on some phones;
  /// coming back from it must not lock again.
  bool _authenticating = false;

  /// Creates the platform channel lazily so tests without the plugin can
  /// still build the controller.
  LocalAuthentication Function() authFactory = LocalAuthentication.new;

  /// Replaced in tests.
  DateTime Function() now = DateTime.now;

  @override
  bool build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    // Turning the lock off in Settings must unlock; turning it on must not
    // lock the screen the user is looking at.
    ref.listen(settingsProvider.select((s) => s.appLockEnabled), (previous, enabled) {
      if (!enabled) state = false;
    });
    return ref.read(settingsProvider).appLockEnabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsProvider);
    if (!settings.appLockEnabled || _authenticating) return;
    switch (state) {
      case AppLifecycleState.paused:
        _backgroundSince ??= now();
      case AppLifecycleState.resumed:
        final since = _backgroundSince;
        _backgroundSince = null;
        if (since != null && now().difference(since).inSeconds >= settings.lockDelay.seconds) this.state = true;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Checks [pin]; unlocks when it is right.
  bool unlockWithPin(String pin) {
    final ok = ref.read(settingsProvider.notifier).verifyPin(pin);
    if (ok) state = false;
    return ok;
  }

  /// Shows the system fingerprint / face prompt; unlocks on success.
  Future<bool> unlockWithBiometrics(String reason) async {
    _authenticating = true;
    try {
      final ok = await authFactory().authenticate(localizedReason: reason, biometricOnly: true);
      if (ok) state = false;
      return ok;
    } catch (_) {
      return false;
    } finally {
      _authenticating = false;
      _backgroundSince = null;
    }
  }

  void lock() => state = true;
}
