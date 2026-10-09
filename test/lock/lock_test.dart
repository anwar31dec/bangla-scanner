import 'package:banglascanner/core/models/enums.dart';
import 'package:banglascanner/features/lock/application/lock_controller.dart';
import 'package:banglascanner/features/settings/application/settings_controller.dart';
import 'package:banglascanner/features/settings/data/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_app.dart';

Future<ProviderContainer> _container({Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(instance)]);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepository PIN', () {
    test('stores a salted hash and verifies only the right PIN', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(prefs);
      expect(repo.hasPin, isFalse);
      await repo.setPin('2468');
      expect(repo.hasPin, isTrue);
      expect(repo.verifyPin('2468'), isTrue);
      expect(repo.verifyPin('2469'), isFalse);
      expect(prefs.getString('settings.lock.pinHash'), isNot(contains('2468')));
      await repo.clearPin();
      expect(repo.hasPin, isFalse);
      expect(repo.verifyPin('2468'), isFalse);
    });

    test('a lock flag without a PIN is ignored', () async {
      SharedPreferences.setMockInitialValues({'settings.lock.enabled': true});
      final repo = SettingsRepository(await SharedPreferences.getInstance());
      expect(repo.load().appLockEnabled, isFalse);
    });
  });

  group('LockController', () {
    test('is unlocked when the lock is off', () async {
      final c = await _container();
      addTearDown(c.dispose);
      expect(c.read(lockControllerProvider), isFalse);
    });

    test('locks on launch, unlocks with the PIN, re-locks after the delay', () async {
      final c = await _container();
      addTearDown(c.dispose);
      // The gate creates the controller on the first frame, before the user
      // can reach Settings.
      expect(c.read(lockControllerProvider), isFalse);
      await c.read(settingsProvider.notifier).enableAppLock('1357');
      await c.read(settingsProvider.notifier).setLockDelay(LockDelay.oneMinute);
      // Enabling the lock while using the app must not lock the screen.
      expect(c.read(lockControllerProvider), isFalse);

      // A fresh start reads the saved settings: locked.
      final restarted = await _container(prefs: {
        'settings.lock.enabled': true,
        'settings.lock.pinSalt': c.read(sharedPreferencesProvider).getString('settings.lock.pinSalt')!,
        'settings.lock.pinHash': c.read(sharedPreferencesProvider).getString('settings.lock.pinHash')!,
        'settings.lock.delay': 'oneMinute',
      });
      addTearDown(restarted.dispose);
      expect(restarted.read(lockControllerProvider), isTrue);

      final lock = restarted.read(lockControllerProvider.notifier);
      expect(lock.unlockWithPin('0000'), isFalse);
      expect(restarted.read(lockControllerProvider), isTrue);
      expect(lock.unlockWithPin('1357'), isTrue);
      expect(restarted.read(lockControllerProvider), isFalse);

      // Short trip to the background: stays unlocked.
      var clock = DateTime(2026, 10, 9, 12);
      lock.now = () => clock;
      lock.didChangeAppLifecycleState(AppLifecycleState.paused);
      clock = clock.add(const Duration(seconds: 30));
      lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(restarted.read(lockControllerProvider), isFalse);

      // Longer than the delay: locked again.
      lock.didChangeAppLifecycleState(AppLifecycleState.paused);
      clock = clock.add(const Duration(seconds: 61));
      lock.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(restarted.read(lockControllerProvider), isTrue);

      // Turning the lock off in Settings unlocks.
      await restarted.read(settingsProvider.notifier).disableAppLock();
      expect(restarted.read(lockControllerProvider), isFalse);
    });
  });

  testWidgets('lock screen covers the app and opens with the PIN', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final seed = SettingsRepository(await SharedPreferences.getInstance());
    await seed.setPin('4321');
    final prefs = await SharedPreferences.getInstance();
    final (app, db, _) = await buildTestApp(prefs: {
      'settings.language': 'en',
      'settings.lock.enabled': true,
      'settings.lock.pinSalt': prefs.getString('settings.lock.pinSalt')!,
      'settings.lock.pinHash': prefs.getString('settings.lock.pinHash')!,
    });
    addTearDown(db.close);
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(find.text('Bangla Scanner is locked'), findsOneWidget);

    for (final d in ['1', '1', '1', '1']) {
      await tester.tap(find.widgetWithText(InkWell, d));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('Wrong PIN'), findsOneWidget);

    for (final d in ['4', '3', '2', '1']) {
      await tester.tap(find.widgetWithText(InkWell, d));
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('Bangla Scanner is locked'), findsNothing);
    expect(find.text('Scan'), findsWidgets, reason: 'home screen is visible again');
    await unmountApp(tester);
  });
}
