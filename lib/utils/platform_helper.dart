import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformHelper {
  // Platform detection
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  // Platform-specific configurations
  static String get platformName {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isWindows) return 'windows';
    if (isMacOS) return 'macos';
    if (isLinux) return 'linux';
    return 'unknown';
  }
  
  // Method to get platform name as string
  static String getPlatformName() {
    return platformName;
  }

  // File handling based on platform
  static bool get supportsFilePicker => !isWeb || kDebugMode;
  static bool get supportsCamera => isMobile;
  static bool get supportsNotifications => !isWeb;
  static bool get supportsBackgroundTasks => isMobile;

  // UI adaptations
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 600 && width < 1200;
  }

  static bool isDesktopScreen(BuildContext context) {
    return getScreenWidth(context) >= 1200;
  }

  // Platform-specific storage paths
  static String getStoragePath() {
    if (isAndroid) return '/storage/emulated/0/CareSync/';
    if (isIOS) return 'Documents/CareSync/';
    if (isWindows) return 'C:/Users/Documents/CareSync/';
    if (isMacOS) return '~/Documents/CareSync/';
    return 'CareSync/';
  }
}