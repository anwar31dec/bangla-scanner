import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Installer package name reported by Google Play for apps it installed.
const String playStoreInstaller = 'com.android.vending';

/// Plugin-independent view of Play's update availability.
enum UpdateAvailabilityStatus { unknown, notAvailable, available, inProgress }

/// Plugin-independent result of an immediate update attempt.
enum ImmediateUpdateResult { success, userDenied, failed }

class UpdateCheck {
  const UpdateCheck({
    required this.availability,
    required this.immediateAllowed,
    this.availableVersionCode,
  });

  final UpdateAvailabilityStatus availability;
  final bool immediateAllowed;
  final int? availableVersionCode;
}

/// Thin seam over the Play In-App Updates API so [AppUpdateService] can be
/// unit-tested without platform channels.
abstract class InAppUpdateGateway {
  Future<UpdateCheck> checkForUpdate();
  Future<ImmediateUpdateResult> performImmediateUpdate();
}

/// Default gateway backed by the `in_app_update` plugin.
class PlayInAppUpdateGateway implements InAppUpdateGateway {
  const PlayInAppUpdateGateway();

  @override
  Future<UpdateCheck> checkForUpdate() async {
    final info = await InAppUpdate.checkForUpdate();
    return UpdateCheck(
      availability: switch (info.updateAvailability) {
        UpdateAvailability.updateNotAvailable => UpdateAvailabilityStatus.notAvailable,
        UpdateAvailability.updateAvailable => UpdateAvailabilityStatus.available,
        UpdateAvailability.developerTriggeredUpdateInProgress => UpdateAvailabilityStatus.inProgress,
        UpdateAvailability.unknown => UpdateAvailabilityStatus.unknown,
      },
      immediateAllowed: info.immediateUpdateAllowed,
      availableVersionCode: info.availableVersionCode,
    );
  }

  @override
  Future<ImmediateUpdateResult> performImmediateUpdate() async {
    final result = await InAppUpdate.performImmediateUpdate();
    return switch (result) {
      AppUpdateResult.success => ImmediateUpdateResult.success,
      AppUpdateResult.userDeniedUpdate => ImmediateUpdateResult.userDenied,
      AppUpdateResult.inAppUpdateFailed => ImmediateUpdateResult.failed,
    };
  }
}

enum AppUpdateOutcome {
  /// Not running on Android; Play in-app updates are unavailable.
  skippedPlatform,

  /// The app was not installed by Google Play (dev flavor via App
  /// Distribution, sideload, emulator), so the Play API would reject the call.
  skippedNotPlayInstall,

  /// A check is already in progress.
  alreadyRunning,

  /// Play reports no newer version.
  upToDate,

  /// Play's immediate-update flow was launched (or resumed) and completed.
  /// For immediate updates Play normally restarts the app before this value
  /// is ever observed.
  updateStarted,

  /// Play offered the update and the user cancelled it.
  userDeclined,

  /// The check or the update flow failed; the error was logged.
  failed,
}

/// Checks Google Play for a newer version on app open and, if one exists,
/// launches Play's full-screen *immediate* update flow (download, install,
/// restart). Never throws: the update path must not interfere with normal use.
///
/// Same behaviour as Hisab Master, Bijoy Converter and ePharma.
class AppUpdateService {
  AppUpdateService(
    this._gateway, {
    required this._isAndroid,
    required this._installerStore,
  });

  final InAppUpdateGateway _gateway;
  final bool _isAndroid;
  final Future<String?> Function() _installerStore;
  bool _inFlight = false;

  Future<AppUpdateOutcome> checkAndUpdate() async {
    if (!_isAndroid) return AppUpdateOutcome.skippedPlatform;
    if (_inFlight) return AppUpdateOutcome.alreadyRunning;
    _inFlight = true;
    try {
      final installer = await _installerStore();
      if (installer != playStoreInstaller) {
        debugPrint('In-app update skipped: installer is ${installer ?? 'unknown'}');
        return AppUpdateOutcome.skippedNotPlayInstall;
      }

      final check = await _gateway.checkForUpdate();
      debugPrint('In-app update check: ${check.availability}, '
          'immediateAllowed=${check.immediateAllowed}, '
          'availableVersionCode=${check.availableVersionCode}');

      final shouldUpdate = switch (check.availability) {
        UpdateAvailabilityStatus.available => check.immediateAllowed,
        // An immediate update that was interrupted (user backgrounded the app
        // mid-download); Google recommends resuming it.
        UpdateAvailabilityStatus.inProgress => true,
        UpdateAvailabilityStatus.notAvailable || UpdateAvailabilityStatus.unknown => false,
      };
      if (!shouldUpdate) return AppUpdateOutcome.upToDate;

      return switch (await _gateway.performImmediateUpdate()) {
        ImmediateUpdateResult.success => AppUpdateOutcome.updateStarted,
        ImmediateUpdateResult.userDenied => AppUpdateOutcome.userDeclined,
        ImmediateUpdateResult.failed => AppUpdateOutcome.failed,
      };
    } catch (e, stack) {
      debugPrint('In-app update check failed: $e\n$stack');
      return AppUpdateOutcome.failed;
    } finally {
      _inFlight = false;
    }
  }
}

/// Android-only Google Play immediate update. No-op for non-Play installs
/// (dev flavor via Firebase App Distribution, sideloads, emulator) and on iOS.
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(
    const PlayInAppUpdateGateway(),
    isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    installerStore: () async => (await PackageInfo.fromPlatform()).installerStore,
  );
});
