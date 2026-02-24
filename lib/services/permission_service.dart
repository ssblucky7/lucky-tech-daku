import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:finalapp/utils/platform_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    if (PlatformUtils.isWeb) return true;
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> requestStoragePermission() async {
    if (PlatformUtils.isWeb) return true;
    if (PlatformUtils.isAndroid) {
      final status = await Permission.storage.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  static Future<bool> requestLocationPermission() async {
    if (PlatformUtils.isWeb) return true;
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> requestPhotosPermission() async {
    if (PlatformUtils.isWeb) return true;
    
    if (PlatformUtils.isAndroid) {
      // Android 13+ uses granular media permissions
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.photos.request();
        return status == PermissionStatus.granted;
      } else {
        final status = await Permission.storage.request();
        return status == PermissionStatus.granted;
      }
    } else if (PlatformUtils.isIOS) {
      final status = await Permission.photos.request();
      return status == PermissionStatus.granted;
    }
    
    return true;
  }

  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
      List<Permission> permissions) async {
    return await permissions.request();
  }

  static Future<bool> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status == PermissionStatus.granted;
  }

  static void showPermissionDialog(BuildContext context, String permissionName, VoidCallback onRetry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text('This app needs $permissionName permission to function properly. Please grant permission in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
