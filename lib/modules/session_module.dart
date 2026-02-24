import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:finalapp/modules/account_module.dart';

class SessionModule {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Map<String, dynamic>? _cachedAccount;
  static UserRole? _cachedRole;

  // Initialize session
  static Future<void> initializeSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _cachedAccount = await AccountModule.getCurrentAccount();
      _cachedRole = await AccountModule.getUserRole();

      await _createSessionRecord();
      
      if (kDebugMode) {
        debugPrint('Session initialized for ${user.email}');
        debugPrint('Role: ${_cachedRole?.name}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing session: $e');
    }
  }

  // Create session record
  static Future<void> _createSessionRecord() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('caresync_sessions').add({
      'user_id': user.uid,
      'email': user.email,
      'role': _cachedRole?.name,
      'login_time': FieldValue.serverTimestamp(),
      'device_info': {
        'platform': kIsWeb ? 'web' : 'mobile',
      },
    });
  }

  // Clear session
  static Future<void> clearSession() async {
    _cachedAccount = null;
    _cachedRole = null;
    
    if (kDebugMode) debugPrint('Session cleared');
  }

  // Get cached account
  static Map<String, dynamic>? getCachedAccount() => _cachedAccount;

  // Get cached role
  static UserRole? getCachedRole() => _cachedRole;

  // Refresh session
  static Future<void> refreshSession() async {
    await initializeSession();
  }

  // Check if session is valid
  static bool isSessionValid() {
    return _auth.currentUser != null && _cachedAccount != null;
  }
}
