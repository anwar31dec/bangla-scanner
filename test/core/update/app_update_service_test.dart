import 'package:banglascanner/core/update/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements InAppUpdateGateway {
  _FakeGateway(this.check, {this.result = ImmediateUpdateResult.success});
  final UpdateCheck check;
  final ImmediateUpdateResult result;
  int checks = 0;
  int updates = 0;

  @override
  Future<UpdateCheck> checkForUpdate() async {
    checks++;
    return check;
  }

  @override
  Future<ImmediateUpdateResult> performImmediateUpdate() async {
    updates++;
    return result;
  }
}

class _ThrowingGateway implements InAppUpdateGateway {
  @override
  Future<UpdateCheck> checkForUpdate() async => throw StateError('Play unavailable');

  @override
  Future<ImmediateUpdateResult> performImmediateUpdate() async => throw StateError('unreachable');
}

const _available = UpdateCheck(
  availability: UpdateAvailabilityStatus.available,
  immediateAllowed: true,
  availableVersionCode: 42,
);

AppUpdateService _service(InAppUpdateGateway g, {bool android = true, String? installer = playStoreInstaller}) =>
    AppUpdateService(g, isAndroid: android, installerStore: () async => installer);

void main() {
  test('skips on non-Android without touching Play', () async {
    final g = _FakeGateway(_available);
    expect(await _service(g, android: false).checkAndUpdate(), AppUpdateOutcome.skippedPlatform);
    expect(g.checks, 0);
  });

  test('skips when not installed from Google Play (dev / sideload)', () async {
    final g = _FakeGateway(_available);
    expect(await _service(g, installer: null).checkAndUpdate(), AppUpdateOutcome.skippedNotPlayInstall);
    expect(await _service(g, installer: 'com.google.android.packageinstaller').checkAndUpdate(),
        AppUpdateOutcome.skippedNotPlayInstall);
    expect(g.checks, 0);
  });

  test('launches immediate update when Play has a newer version', () async {
    final g = _FakeGateway(_available);
    expect(await _service(g).checkAndUpdate(), AppUpdateOutcome.updateStarted);
    expect(g.updates, 1);
  });

  test('resumes an interrupted immediate update', () async {
    final g = _FakeGateway(const UpdateCheck(
      availability: UpdateAvailabilityStatus.inProgress,
      immediateAllowed: false,
    ));
    expect(await _service(g).checkAndUpdate(), AppUpdateOutcome.updateStarted);
  });

  test('does nothing when up to date or immediate not allowed', () async {
    final upToDate = _FakeGateway(const UpdateCheck(
      availability: UpdateAvailabilityStatus.notAvailable,
      immediateAllowed: true,
    ));
    expect(await _service(upToDate).checkAndUpdate(), AppUpdateOutcome.upToDate);
    final flexibleOnly = _FakeGateway(const UpdateCheck(
      availability: UpdateAvailabilityStatus.available,
      immediateAllowed: false,
    ));
    expect(await _service(flexibleOnly).checkAndUpdate(), AppUpdateOutcome.upToDate);
    expect(upToDate.updates + flexibleOnly.updates, 0);
  });

  test('reports user decline and failures without throwing', () async {
    expect(await _service(_FakeGateway(_available, result: ImmediateUpdateResult.userDenied)).checkAndUpdate(),
        AppUpdateOutcome.userDeclined);
    expect(await _service(_FakeGateway(_available, result: ImmediateUpdateResult.failed)).checkAndUpdate(),
        AppUpdateOutcome.failed);
    expect(await _service(_ThrowingGateway()).checkAndUpdate(), AppUpdateOutcome.failed);
  });

  test('a second call while one is in flight is rejected', () async {
    final g = _FakeGateway(_available);
    final s = _service(g);
    final first = s.checkAndUpdate();
    expect(await s.checkAndUpdate(), AppUpdateOutcome.alreadyRunning);
    expect(await first, AppUpdateOutcome.updateStarted);
    expect(g.checks, 1);
  });
}
