import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Version shown in Settings and written into backups.
///
/// Read from the installed package (Android `versionName`, i.e. the part of
/// `version:` in pubspec.yaml before the `+`, plus the dev flavour's `-dev`
/// suffix), so it never has to be edited by hand. `main()` loads it with
/// [loadAppVersion] and overrides this provider before the first frame.
final appVersionProvider = Provider<String>((_) => 'unknown');

Future<String> loadAppVersion() async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } catch (_) {
    return 'unknown';
  }
}
