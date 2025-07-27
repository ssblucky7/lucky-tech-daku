import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _profilesCollection = 'caresync_profiles';
  static const String _medicalHistoryCollection = 'caresync_medical_history';
  static const String _feedbackCollection = 'caresync_feedback';

  // Create or update user profile
  static Future<String> createOrUpdateProfile({
    required String name,
    required String email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? emergencyContact,
    PlatformFile? profileImage,
    Map<String, dynamic>? medicalInfo,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_profilesCollection).doc(userId);
      
      String? imageUrl;
      String? imageName;
      String? publicId;
      
      // Upload profile image to Cloudinary if provided
      if (profileImage != null) {
        final uploadResult = await CloudinaryService.uploadFile(profileImage);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          imageUrl = uploadResult['url'];
          imageName = profileImage.name;
          publicId = uploadResult['public_id'];
        }
      }

      final profileData = {
        'user_id': userId,
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'date_of_birth': dateOfBirth ?? '',
        'gender': gender ?? '',
        'blood_group': bloodGroup ?? '',
        'address': address ?? '',
        'emergency_contact': emergencyContact ?? '',
        'profile_image_url': imageUrl,
        'profile_image_name': imageName,
        'public_id': publicId,
        'medical_info': medicalInfo ?? {},
        'is_email_verified': user?.emailVerified ?? false,
        'last_login': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(profileData, SetOptions(merge: true));
      
      if (kDebugMode) {
        debugPrint('Profile updated: $userId');
      }
      
      return userId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating profile: $e');
      }
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final doc = await _firestore.collection(_profilesCollection).doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        
        if (kDebugMode) {
          debugPrint('Profile loaded for user: $userId');
        }
        
        return data;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting profile: $e');
      }
      return null;
    }
  }

  // Add medical history record
  static Future<String> addMedicalHistory({
    required String title,
    required String description,
    required DateTime date,
    String? doctorName,
    String? hospitalName,
    String? diagnosis,
    String? treatment,
    List<String>? medications,
    PlatformFile? document,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_medicalHistoryCollection).doc();
      
      String? documentUrl;
      String? documentName;
      String? publicId;
      
      // Upload document to Cloudinary if provided
      if (document != null) {
        final uploadResult = await CloudinaryService.uploadFile(document);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          documentUrl = uploadResult['url'];
          documentName = document.name;
          publicId = uploadResult['public_id'];
        }
      }

      final historyData = {
        'id': docRef.id,
        'user_id': userId,
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'doctor_name': doctorName ?? '',
        'hospital_name': hospitalName ?? '',
        'diagnosis': diagnosis ?? '',
        'treatment': treatment ?? '',
        'medications': medications ?? [],
        'document_url': documentUrl,
        'document_name': documentName,
        'public_id': publicId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(historyData);
      
      if (kDebugMode) {
        debugPrint('Medical history added: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding medical history: $e');
      }
      throw Exception('Failed to add medical history: $e');
    }
  }

  // Get medical history
  static Future<List<Map<String, dynamic>>> getMedicalHistory() async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final snapshot = await _firestore
          .collection(_medicalHistoryCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} medical history records');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting medical history: $e');
      }
      return [];
    }
  }

  // Delete medical history record
  static Future<void> deleteMedicalHistory(String historyId) async {
    try {
      final doc = await _firestore.collection(_medicalHistoryCollection).doc(historyId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        // Delete document from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        // Delete document from Firestore
        await _firestore.collection(_medicalHistoryCollection).doc(historyId).delete();
        
        if (kDebugMode) {
          debugPrint('Medical history deleted: $historyId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting medical history: $e');
      }
      throw Exception('Failed to delete medical history: $e');
    }
  }

  // Submit feedback
  static Future<String> submitFeedback({
    required String feedback,
    String? category,
    int? rating,
    PlatformFile? attachment,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_feedbackCollection).doc();
      
      String? attachmentUrl;
      String? attachmentName;
      String? publicId;
      
      // Upload attachment to Cloudinary if provided
      if (attachment != null) {
        final uploadResult = await CloudinaryService.uploadFile(attachment);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          attachmentUrl = uploadResult['url'];
          attachmentName = attachment.name;
          publicId = uploadResult['public_id'];
        }
      }

      final feedbackData = {
        'id': docRef.id,
        'user_id': userId,
        'feedback': feedback,
        'category': category ?? 'general',
        'rating': rating ?? 5,
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'public_id': publicId,
        'status': 'submitted',
        'created_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(feedbackData);
      
      if (kDebugMode) {
        debugPrint('Feedback submitted: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error submitting feedback: $e');
      }
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // Get user statistics
  static Future<Map<String, int>> getUserStatistics() async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final results = await Future.wait([
        _firestore.collection('caresync_consultations').where('user_id', isEqualTo: userId).get(),
        _firestore.collection('caresync_medications').where('user_id', isEqualTo: userId).get(),
        _firestore.collection('caresync_reports').where('user_id', isEqualTo: userId).get(),
        _firestore.collection(_medicalHistoryCollection).where('user_id', isEqualTo: userId).get(),
      ]);

      return {
        'appointments': results[0].docs.length,
        'medications': results[1].docs.length,
        'reports': results[2].docs.length,
        'medical_history': results[3].docs.length,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user statistics: $e');
      }
      return {
        'appointments': 0,
        'medications': 0,
        'reports': 0,
        'medical_history': 0,
      };
    }
  }

  // Update profile image
  static Future<void> updateProfileImage(PlatformFile imageFile) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      // Get current profile to delete old image
      final currentProfile = await getUserProfile();
      final oldPublicId = currentProfile?['public_id'] as String?;

      // Upload new image
      final uploadResult = await CloudinaryService.uploadFile(imageFile);
      
      if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
        // Update profile with new image
        await _firestore.collection(_profilesCollection).doc(userId).update({
          'profile_image_url': uploadResult['url'],
          'profile_image_name': imageFile.name,
          'public_id': uploadResult['public_id'],
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Delete old image from Cloudinary
        if (oldPublicId != null) {
          await CloudinaryService.deleteFile(oldPublicId);
        }

        if (kDebugMode) {
          debugPrint('Profile image updated for user: $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating profile image: $e');
      }
      throw Exception('Failed to update profile image: $e');
    }
  }

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        
        if (kDebugMode) {
          debugPrint('Email verification sent to: ${user.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending email verification: $e');
      }
      throw Exception('Failed to send email verification: $e');
    }
  }

  // Update email verification status
  static Future<void> updateEmailVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = _auth.currentUser;
        
        if (updatedUser?.emailVerified == true) {
          await _firestore.collection(_profilesCollection).doc(user.uid).update({
            'is_email_verified': true,
            'updated_at': FieldValue.serverTimestamp(),
          });
          
          if (kDebugMode) {
            debugPrint('Email verification status updated');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating email verification status: $e');
      }
    }
  }

  // Delete user profile and all associated data
  static Future<void> deleteUserProfile() async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      // Get profile to delete images
      final profile = await getUserProfile();
      final profilePublicId = profile?['public_id'] as String?;

      // Get medical history to delete documents
      final medicalHistory = await getMedicalHistory();

      // Delete all Cloudinary files
      if (profilePublicId != null) {
        await CloudinaryService.deleteFile(profilePublicId);
      }

      for (final history in medicalHistory) {
        final publicId = history['public_id'] as String?;
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
      }

      // Delete all Firestore documents
      final batch = _firestore.batch();
      
      // Delete profile
      batch.delete(_firestore.collection(_profilesCollection).doc(userId));
      
      // Delete medical history
      for (final history in medicalHistory) {
        batch.delete(_firestore.collection(_medicalHistoryCollection).doc(history['id']));
      }
      
      // Delete feedback
      final feedbackSnapshot = await _firestore
          .collection(_feedbackCollection)
          .where('user_id', isEqualTo: userId)
          .get();
      
      for (final doc in feedbackSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      if (kDebugMode) {
        debugPrint('User profile and data deleted: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting user profile: $e');
      }
      throw Exception('Failed to delete user profile: $e');
    }
  }
}