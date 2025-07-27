import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';

class DoctorConsultationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _doctorsCollection = 'caresync_doctors';
  static const String _consultationsCollection = 'caresync_consultations';

  // Create a new doctor
  static Future<String> createDoctor({
    required String name,
    required String specialty,
    required String hospital,
    required double rating,
    required int experience,
    required int consultationFee,
    required List<String> availability,
    required String about,
    PlatformFile? profileImage,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_doctorsCollection).doc();
      
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

      final doctorData = {
        'id': docRef.id,
        'user_id': userId,
        'name': name,
        'specialty': specialty,
        'hospital': hospital,
        'rating': rating,
        'experience': experience,
        'consultation_fee': consultationFee,
        'availability': availability,
        'about': about,
        'profile_image_url': imageUrl,
        'profile_image_name': imageName,
        'public_id': publicId,
        'is_active': true,
        'total_consultations': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(doctorData);
      
      if (kDebugMode) {
        debugPrint('Doctor created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating doctor: $e');
      }
      throw Exception('Failed to create doctor: $e');
    }
  }

  // Get all doctors
  static Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final snapshot = await _firestore
          .collection(_doctorsCollection)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} doctors in collection');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (kDebugMode) {
          debugPrint('Doctor data: ${data['name']}');
        }
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting doctors: $e');
      }
      return [];
    }
  }

  // Book consultation
  static Future<String> bookConsultation({
    required String doctorId,
    required DateTime dateTime,
    required String consultationType,
    required List<String> symptoms,
    required String notes,
    PlatformFile? medicalDocument,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_consultationsCollection).doc();
      
      String? documentUrl;
      String? documentName;
      String? publicId;
      
      // Upload medical document to Cloudinary if provided
      if (medicalDocument != null) {
        final uploadResult = await CloudinaryService.uploadFile(medicalDocument);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          documentUrl = uploadResult['url'];
          documentName = medicalDocument.name;
          publicId = uploadResult['public_id'];
        }
      }

      final consultationData = {
        'id': docRef.id,
        'user_id': userId,
        'doctor_id': doctorId,
        'date_time': Timestamp.fromDate(dateTime),
        'consultation_type': consultationType,
        'status': 'pending',
        'symptoms': symptoms,
        'notes': notes,
        'medical_document_url': documentUrl,
        'medical_document_name': documentName,
        'public_id': publicId,
        'prescription': null,
        'follow_up_date': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(consultationData);
      
      if (kDebugMode) {
        debugPrint('Consultation booked: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error booking consultation: $e');
      }
      throw Exception('Failed to book consultation: $e');
    }
  }

  // Get consultations
  static Future<List<Map<String, dynamic>>> getConsultations() async {
    try {
      final snapshot = await _firestore
          .collection(_consultationsCollection)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} consultations in collection');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting consultations: $e');
      }
      return [];
    }
  }

  // Get upcoming consultations
  static Future<List<Map<String, dynamic>>> getUpcomingConsultations() async {
    try {
      final snapshot = await _firestore
          .collection(_consultationsCollection)
          .orderBy('created_at', descending: true)
          .get();

      final now = DateTime.now();
      final upcoming = snapshot.docs.where((doc) {
        final data = doc.data();
        final dateTime = (data['date_time'] as Timestamp).toDate();
        final status = data['status'] as String;
        return dateTime.isAfter(now) && (status == 'pending' || status == 'confirmed');
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('Found ${upcoming.length} upcoming consultations');
      }

      return upcoming;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting upcoming consultations: $e');
      }
      return [];
    }
  }

  // Get past consultations
  static Future<List<Map<String, dynamic>>> getPastConsultations() async {
    try {
      final snapshot = await _firestore
          .collection(_consultationsCollection)
          .orderBy('created_at', descending: true)
          .get();

      final now = DateTime.now();
      final past = snapshot.docs.where((doc) {
        final data = doc.data();
        final dateTime = (data['date_time'] as Timestamp).toDate();
        return dateTime.isBefore(now) || data['status'] == 'completed' || data['status'] == 'cancelled';
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        debugPrint('Found ${past.length} past consultations');
      }

      return past;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting past consultations: $e');
      }
      return [];
    }
  }

  // Update consultation
  static Future<void> updateConsultation({
    required String consultationId,
    String? status,
    DateTime? dateTime,
    String? prescription,
    DateTime? followUpDate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (status != null) updateData['status'] = status;
      if (dateTime != null) updateData['date_time'] = Timestamp.fromDate(dateTime);
      if (prescription != null) updateData['prescription'] = prescription;
      if (followUpDate != null) updateData['follow_up_date'] = Timestamp.fromDate(followUpDate);

      await _firestore.collection(_consultationsCollection).doc(consultationId).update(updateData);
      
      if (kDebugMode) {
        debugPrint('Consultation updated: $consultationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating consultation: $e');
      }
      throw Exception('Failed to update consultation: $e');
    }
  }

  // Cancel consultation
  static Future<void> cancelConsultation(String consultationId) async {
    try {
      await updateConsultation(
        consultationId: consultationId,
        status: 'cancelled',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cancelling consultation: $e');
      }
      throw Exception('Failed to cancel consultation: $e');
    }
  }

  // Reschedule consultation
  static Future<void> rescheduleConsultation(String consultationId, DateTime newDateTime) async {
    try {
      await updateConsultation(
        consultationId: consultationId,
        dateTime: newDateTime,
        status: 'pending',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error rescheduling consultation: $e');
      }
      throw Exception('Failed to reschedule consultation: $e');
    }
  }

  // Delete consultation
  static Future<void> deleteConsultation(String consultationId) async {
    try {
      final doc = await _firestore.collection(_consultationsCollection).doc(consultationId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        // Delete document from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        // Delete document from Firestore
        await _firestore.collection(_consultationsCollection).doc(consultationId).delete();
        
        if (kDebugMode) {
          debugPrint('Consultation deleted: $consultationId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting consultation: $e');
      }
      throw Exception('Failed to delete consultation: $e');
    }
  }

  // Search doctors
  static Future<List<Map<String, dynamic>>> searchDoctors(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_doctorsCollection)
          .where('is_active', isEqualTo: true)
          .get();

      final doctors = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter by query
      return doctors.where((doctor) {
        return doctor['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
               doctor['specialty'].toString().toLowerCase().contains(query.toLowerCase()) ||
               doctor['hospital'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching doctors: $e');
      }
      return [];
    }
  }

  // Filter doctors
  static Future<List<Map<String, dynamic>>> filterDoctors({
    String? specialty,
    double? minRating,
    int? minExperience,
  }) async {
    try {
      Query query = _firestore
          .collection(_doctorsCollection)
          .where('is_active', isEqualTo: true);

      if (specialty != null) {
        query = query.where('specialty', isEqualTo: specialty);
      }
      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }
      if (minExperience != null) {
        query = query.where('experience', isGreaterThanOrEqualTo: minExperience);
      }

      final snapshot = await query.orderBy('rating', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error filtering doctors: $e');
      }
      return [];
    }
  }

  // Get doctor by ID
  static Future<Map<String, dynamic>?> getDoctor(String doctorId) async {
    try {
      final doc = await _firestore.collection(_doctorsCollection).doc(doctorId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting doctor: $e');
      }
      return null;
    }
  }

  // Get consultation with doctor details
  static Future<Map<String, dynamic>?> getConsultationWithDoctor(String consultationId) async {
    try {
      final consultationDoc = await _firestore.collection(_consultationsCollection).doc(consultationId).get();
      
      if (consultationDoc.exists) {
        final consultationData = consultationDoc.data()!;
        consultationData['id'] = consultationDoc.id;
        
        // Get doctor details
        final doctorData = await getDoctor(consultationData['doctor_id']);
        if (doctorData != null) {
          consultationData['doctor'] = doctorData;
        }
        
        return consultationData;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting consultation with doctor: $e');
      }
      return null;
    }
  }
}