import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProfileSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Sync profile data across all collections
  static Future<void> syncProfileAcrossSystem({
    required String name,
    required String email,
    String? phone,
    String? bloodGroup,
    String? profileImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      // Update profile in all relevant collections
      final collections = [
        'caresync_consultations',
        'caresync_medications',
        'caresync_reports',
        'caresync_medical_history',
        'caresync_appointments',
        'caresync_family_members',
      ];

      for (final collection in collections) {
        final snapshot = await _firestore
            .collection(collection)
            .where('user_id', isEqualTo: userId)
            .get();

        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {
            'user_name': name,
            'user_email': email,
            if (phone != null) 'user_phone': phone,
            if (bloodGroup != null) 'user_blood_group': bloodGroup,
            if (profileImageUrl != null) 'user_profile_image': profileImageUrl,
            'profile_synced_at': timestamp,
          });
        }
      }

      await batch.commit();
      
      if (kDebugMode) {
        debugPrint('Profile synced across system for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error syncing profile: $e');
      }
    }
  }

  // Get cached profile data
  static Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('caresync_profiles')
          .doc(user.uid)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting cached profile: $e');
      }
      return null;
    }
  }

  // Listen to profile changes
  static Stream<Map<String, dynamic>?> profileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('caresync_profiles')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // Auto-sync on profile update
  static Future<void> autoSyncOnUpdate(Map<String, dynamic> profileData) async {
    await syncProfileAcrossSystem(
      name: profileData['name'] ?? '',
      email: profileData['email'] ?? '',
      phone: profileData['phone'],
      bloodGroup: profileData['blood_group'],
      profileImageUrl: profileData['profile_image_url'],
    );
  }
}
