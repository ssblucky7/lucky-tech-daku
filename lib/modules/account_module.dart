import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum UserRole { patient, doctor, admin, guest }

enum Permission {
  viewProfile,
  editProfile,
  viewMedicalHistory,
  editMedicalHistory,
  bookAppointment,
  viewAppointments,
  manageAppointments,
  prescribeMedication,
  viewReports,
  generateReports,
  manageUsers,
  viewAnalytics,
  accessAI,
}

class AccountModule {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final Map<UserRole, List<Permission>> _rolePermissions = {
    UserRole.patient: [
      Permission.viewProfile,
      Permission.editProfile,
      Permission.viewMedicalHistory,
      Permission.editMedicalHistory,
      Permission.bookAppointment,
      Permission.viewAppointments,
      Permission.viewReports,
      Permission.accessAI,
    ],
    UserRole.doctor: [
      Permission.viewProfile,
      Permission.editProfile,
      Permission.viewMedicalHistory,
      Permission.viewAppointments,
      Permission.manageAppointments,
      Permission.prescribeMedication,
      Permission.viewReports,
      Permission.generateReports,
      Permission.viewAnalytics,
      Permission.accessAI,
    ],
    UserRole.admin: Permission.values,
    UserRole.guest: [Permission.viewProfile],
  };

  static Future<Map<String, dynamic>?> getCurrentAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('caresync_accounts').doc(user.uid).get();
      
      if (doc.exists) return doc.data();

      return await _createDefaultAccount(user);
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting account: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> _createDefaultAccount(User user) async {
    final account = {
      'user_id': user.uid,
      'email': user.email,
      'role': UserRole.patient.name,
      'is_active': true,
      'is_verified': user.emailVerified,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('caresync_accounts').doc(user.uid).set(account);
    return account;
  }

  static Future<UserRole> getUserRole() async {
    final account = await getCurrentAccount();
    final roleStr = account?['role'] ?? 'patient';
    return UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.patient,
    );
  }

  static Future<bool> hasPermission(Permission permission) async {
    final role = await getUserRole();
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  static Future<void> updateUserRole(String userId, UserRole role) async {
    if (!await hasPermission(Permission.manageUsers)) {
      throw Exception('Insufficient permissions');
    }

    await _firestore.collection('caresync_accounts').doc(userId).update({
      'role': role.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setAccountStatus(String userId, bool isActive) async {
    if (!await hasPermission(Permission.manageUsers)) {
      throw Exception('Insufficient permissions');
    }

    await _firestore.collection('caresync_accounts').doc(userId).update({
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> isAccountActive() async {
    final account = await getCurrentAccount();
    return account?['is_active'] ?? false;
  }

  static Future<List<Permission>> getUserPermissions() async {
    final role = await getUserRole();
    return _rolePermissions[role] ?? [];
  }
}
