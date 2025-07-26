import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPersistenceService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserId = 'user_id';

  // Save login state
  static Future<void> saveLoginState(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, user.email ?? '');
    await prefs.setString(_keyUserId, user.uid);
  }

  // Clear login state
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserId);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get saved user data
  static Future<Map<String, String?>> getSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyUserEmail),
      'userId': prefs.getString(_keyUserId),
    };
  }
}