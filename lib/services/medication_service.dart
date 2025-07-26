import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MedicationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'medications';

  static Future<String> createMedication({
    required String medicationName,
    required String dosage,
    required String frequency,
    required String time,
    required String type,
    String? notes,
    bool isActive = true,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final medicationData = {
        'id': docRef.id,
        'medicationId': 'MED${docRef.id.substring(0, 8).toUpperCase()}',
        'medicationName': medicationName,
        'dosage': dosage,
        'frequency': frequency,
        'time': time,
        'type': type,
        'notes': notes ?? '',
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
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

  static Future<void> updateMedication({
    required String documentId,
    String? medicationName,
    String? dosage,
    String? frequency,
    String? time,
    String? type,
    String? notes,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (medicationName != null) updateData['medicationName'] = medicationName;
      if (dosage != null) updateData['dosage'] = dosage;
      if (frequency != null) updateData['frequency'] = frequency;
      if (time != null) updateData['time'] = time;
      if (type != null) updateData['type'] = type;
      if (notes != null) updateData['notes'] = notes;
      if (isActive != null) updateData['isActive'] = isActive;

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

  static Future<void> deleteMedication(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).delete();
      
      if (kDebugMode) {
        debugPrint('Medication deleted: $documentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting medication: $e');
      }
      throw Exception('Failed to delete medication: $e');
    }
  }

  static Stream<QuerySnapshot> getMedicationsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> getMedications() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: false)
          .get();

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

  static Future<List<Map<String, dynamic>>> getActiveMedications() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
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

  static Future<void> toggleMedicationStatus(String documentId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(documentId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        debugPrint('Medication status toggled: $documentId -> $isActive');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error toggling medication status: $e');
      }
      throw Exception('Failed to toggle medication status: $e');
    }
  }
}