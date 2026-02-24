import 'package:flutter/foundation.dart';
import 'package:finalapp/modules/account_module.dart';

class FeatureAccessModule {
  static final Map<String, List<Permission>> _featurePermissions = {
    'profile': [Permission.viewProfile, Permission.editProfile],
    'medical_history': [Permission.viewMedicalHistory, Permission.editMedicalHistory],
    'appointments': [Permission.viewAppointments, Permission.bookAppointment],
    'medications': [Permission.viewMedicalHistory],
    'reports': [Permission.viewReports],
    'analytics': [Permission.viewAnalytics],
    'ai_chatbot': [Permission.accessAI],
    'admin_panel': [Permission.manageUsers],
  };

  // Check if feature is accessible
  static Future<bool> canAccessFeature(String featureName) async {
    final requiredPermissions = _featurePermissions[featureName];
    if (requiredPermissions == null) return true;

    for (final permission in requiredPermissions) {
      if (await AccountModule.hasPermission(permission)) {
        return true;
      }
    }

    return false;
  }

  // Get accessible features
  static Future<List<String>> getAccessibleFeatures() async {
    final accessible = <String>[];

    for (final feature in _featurePermissions.keys) {
      if (await canAccessFeature(feature)) {
        accessible.add(feature);
      }
    }

    return accessible;
  }

  // Check multiple permissions (AND logic)
  static Future<bool> hasAllPermissions(List<Permission> permissions) async {
    for (final permission in permissions) {
      if (!await AccountModule.hasPermission(permission)) {
        return false;
      }
    }
    return true;
  }

  // Check multiple permissions (OR logic)
  static Future<bool> hasAnyPermission(List<Permission> permissions) async {
    for (final permission in permissions) {
      if (await AccountModule.hasPermission(permission)) {
        return true;
      }
    }
    return false;
  }

  // Get feature description
  static String getFeatureDescription(String featureName) {
    final descriptions = {
      'profile': 'View and edit your profile',
      'medical_history': 'Access medical records',
      'appointments': 'Book and manage appointments',
      'medications': 'Track medications',
      'reports': 'View health reports',
      'analytics': 'View health analytics',
      'ai_chatbot': 'AI health assistant',
      'admin_panel': 'System administration',
    };

    return descriptions[featureName] ?? 'Feature';
  }
}
