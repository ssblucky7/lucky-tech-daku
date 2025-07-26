import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

// This class extends the functionality of PlatformHelper
// Both classes should be consolidated in the future to avoid confusion

class PlatformUtils {
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWeb => kIsWeb;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  // Platform name getter
  static String get platformName {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (!kIsWeb && Platform.isWindows) return 'windows';
    if (!kIsWeb && Platform.isMacOS) return 'macos';
    if (!kIsWeb && Platform.isLinux) return 'linux';
    return 'unknown';
  }
  
  // Method to get platform name as string (for compatibility with PlatformHelper)
  static String getPlatformName() {
    return platformName;
  }

  static Future<String> getDeviceInfo() async {
    if (kIsWeb) {
      return 'Web Browser';
    }
    
    final deviceInfo = DeviceInfoPlugin();
    
    if (isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return 'Android ${androidInfo.version.release}';
    } else if (isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return 'iOS ${iosInfo.systemVersion}';
    }
    
    return 'Unknown Platform';
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }
}
