import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';

class MedicationTrackerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'caresync_medication_tracker';

  // Create a new medication entry
  static Future<String> createMedication({
    required String name,
    required String dosage,
    required String frequency,
    required String instructions,
    required String type,
    required int totalPills,
    required DateTime startDate,
    required DateTime endDate,
    PlatformFile? prescriptionImage,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_collection).doc();
      
      String? imageUrl;
      String? imageName;
      String? publicId;
      
      // Upload prescription image to Cloudinary if provided
      if (prescriptionImage != null) {
        final uploadResult = await CloudinaryService.uploadFile(prescriptionImage);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          imageUrl = uploadResult['url'];
          imageName = prescriptionImage.name;
          publicId = uploadResult['public_id'];
        }
      }

      final medicationData = {
        'id': docRef.id,
        'user_id': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'instructions': instructions,
        'type': type,
        'total_pills': totalPills,
        'remaining_pills': totalPills,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'next_dose': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 8))),
        'is_active': true,
        'prescription_image_url': imageUrl,
        'prescription_image_name': imageName,
        'public_id': publicId,
        'doses_taken': 0,
        'missed_doses': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(medicationData);
      
      if (kDebugMode) {
        debugPrint('Medication created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating medication: $e');
      }
      throw Exception('Failed to create medication: $e');
    }
  }

  // Get all medications
  static Future<List<Map<String, dynamic>>> getMedications() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} medications');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting medications: $e');
      }
      return [];
    }
  }

  // Get medications stream
  static Stream<QuerySnapshot> getMedicationsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Update medication
  static Future<void> updateMedication({
    required String documentId,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
    String? type,
    int? totalPills,
    int? remainingPills,
    bool? isActive,
    DateTime? nextDose,
    int? dosesTaken,
    int? missedDoses,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (dosage != null) updateData['dosage'] = dosage;
      if (frequency != null) updateData['frequency'] = frequency;
      if (instructions != null) updateData['instructions'] = instructions;
      if (type != null) updateData['type'] = type;
      if (totalPills != null) updateData['total_pills'] = totalPills;
      if (remainingPills != null) updateData['remaining_pills'] = remainingPills;
      if (isActive != null) updateData['is_active'] = isActive;
      if (nextDose != null) updateData['next_dose'] = Timestamp.fromDate(nextDose);
      if (dosesTaken != null) updateData['doses_taken'] = dosesTaken;
      if (missedDoses != null) updateData['missed_doses'] = missedDoses;

      await _firestore.collection(_collection).doc(documentId).update(updateData);
      
      if (kDebugMode) {
        debugPrint('Medication updated: $documentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating medication: $e');
      }
      throw Exception('Failed to update medication: $e');
    }
  }

  // Take dose
  static Future<void> takeDose(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final remainingPills = (data['remaining_pills'] as int) - 1;
        final dosesTaken = (data['doses_taken'] as int? ?? 0) + 1;
        
        // Calculate next dose based on frequency
        DateTime nextDose = DateTime.now();
        final frequency = data['frequency'] as String;
        
        if (frequency.contains('Once daily')) {
          nextDose = nextDose.add(const Duration(hours: 24));
        } else if (frequency.contains('Twice daily')) {
          nextDose = nextDose.add(const Duration(hours: 12));
        } else if (frequency.contains('Every 8 hours')) {
          nextDose = nextDose.add(const Duration(hours: 8));
        } else if (frequency.contains('Every 6 hours')) {
          nextDose = nextDose.add(const Duration(hours: 6));
        } else {
          nextDose = nextDose.add(const Duration(hours: 24));
        }

        await updateMedication(
          documentId: documentId,
          remainingPills: remainingPills,
          dosesTaken: dosesTaken,
          nextDose: nextDose,
          isActive: remainingPills > 0,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error taking dose: $e');
      }
      throw Exception('Failed to record dose: $e');
    }
  }

  // Miss dose
  static Future<void> missDose(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        final missedDoses = (data['missed_doses'] as int? ?? 0) + 1;
        
        await updateMedication(
          documentId: documentId,
          missedDoses: missedDoses,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error recording missed dose: $e');
      }
      throw Exception('Failed to record missed dose: $e');
    }
  }

  // Delete medication
  static Future<void> deleteMedication(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        // Delete image from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        // Delete document from Firestore
        await _firestore.collection(_collection).doc(documentId).delete();
        
        if (kDebugMode) {
          debugPrint('Medication deleted: $documentId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting medication: $e');
      }
      throw Exception('Failed to delete medication: $e');
    }
  }

  // Get active medications
  static Future<List<Map<String, dynamic>>> getActiveMedications() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('is_active', isEqualTo: true)
          .orderBy('next_dose', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting active medications: $e');
      }
      return [];
    }
  }

  // Get medication history
  static Future<List<Map<String, dynamic>>> getMedicationHistory() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('is_active', isEqualTo: false)
          .orderBy('updated_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting medication history: $e');
      }
      return [];
    }
  }

  // Search medications
  static Future<List<Map<String, dynamic>>> searchMedications(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .get();

      final medications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter by query
      return medications.where((medication) {
        return medication['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
               medication['type'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching medications: $e');
      }
      return [];
    }
  }
}