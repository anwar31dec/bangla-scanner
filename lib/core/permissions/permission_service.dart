import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/l10n.dart';

/// Runtime permission handling with clear Bangla/English explanations.
///
/// Flow: explain why → ask the OS → if permanently denied, offer a button
/// that opens the app's system settings page.
class PermissionService {
  PermissionService._();

  static const _storageChannel = MethodChannel('com.codeinherit.banglascanner/storage');

  /// Ensures camera access. Returns true when scanning may proceed.
  static Future<bool> ensureCamera(BuildContext context) {
    final l10n = context.l10n;
    return _ensure(
      context,
      Permission.camera,
      title: l10n.permissionCameraTitle,
      body: l10n.permissionCameraBody,
      icon: Icons.photo_camera_outlined,
    );
  }

  /// Ensures we can write to Downloads. Only Android 9 and below need a
  /// permission; newer versions use MediaStore and iOS uses the Files picker.
  static Future<bool> ensureStorageForDownloads(BuildContext context) async {
    if (!Platform.isAndroid) return true;
    final needed = await _storageChannel.invokeMethod<bool>('needsStoragePermission') ?? false;
    if (!needed || !context.mounted) return true;
    final l10n = context.l10n;
    return _ensure(
      context,
      Permission.storage,
      title: l10n.permissionStorageTitle,
      body: l10n.permissionStorageBody,
      icon: Icons.folder_outlined,
    );
  }

  static Future<bool> _ensure(
    BuildContext context,
    Permission permission, {
    required String title,
    required String body,
    required IconData icon,
  }) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (!context.mounted) return false;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await showPermissionDeniedDialog(context);
      return false;
    }

    // Explain before the system dialog appears.
    final proceed = await _showRationale(context, title: title, body: body, icon: icon);
    if (!proceed) return false;

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied && context.mounted) {
      await showPermissionDeniedDialog(context);
    }
    return false;
  }

  static Future<bool> _showRationale(
    BuildContext context, {
    required String title,
    required String body,
    required IconData icon,
  }) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, size: 40),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.notNow)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.allow)),
        ],
      ),
    );
    return result ?? false;
  }

  /// "Permission denied" dialog with a button to the app settings page.
  static Future<void> showPermissionDeniedDialog(BuildContext context) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_outline, size: 40),
        title: Text(l10n.permissionDeniedTitle),
        content: Text(l10n.permissionDeniedBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }
}
