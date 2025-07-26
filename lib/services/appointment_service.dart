import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'appointments';

  static Future<String> createAppointment({
    required String patientName,
    required String doctorName,
    required String specialty,
    required DateTime date,
    required String time,
    required String symptoms,
    String? notes,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final appointmentData = {
        'id': docRef.id,
        'appointmentId': 'APT${docRef.id.substring(0, 8).toUpperCase()}',
        'patient': patientName,
        'doctor': doctorName,
        'specialty': specialty,
        'date': date.toIso8601String(),
        'time': time,
        'status': 'pending',
        'symptoms': symptoms,
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(appointmentData);
      
      if (kDebugMode) {
        debugPrint('Appointment created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating appointment: $e');
      }
      throw Exception('Failed to create appointment: $e');
    }
  }

  static Future<void> updateAppointment({
    required String documentId,
    String? patientName,
    String? doctorName,
    String? specialty,
    DateTime? date,
    String? time,
    String? status,
    String? symptoms,
    String? notes,
    String? diagnosis,
    String? prescription,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (patientName != null) updateData['patient'] = patientName;
      if (doctorName != null) updateData['doctor'] = doctorName;
      if (specialty != null) updateData['specialty'] = specialty;
      if (date != null) updateData['date'] = date.toIso8601String();
      if (time != null) updateData['time'] = time;
      if (status != null) updateData['status'] = status;
      if (symptoms != null) updateData['symptoms'] = symptoms;
      if (notes != null) updateData['notes'] = notes;
      if (diagnosis != null) updateData['diagnosis'] = diagnosis;
      if (prescription != null) updateData['prescription'] = prescription;

      await _firestore.collection(_collection).doc(documentId).update(updateData);
      
      if (kDebugMode) {
        debugPrint('Appointment updated: $documentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating appointment: $e');
      }
      throw Exception('Failed to update appointment: $e');
    }
  }

  static Future<void> deleteAppointment(String documentId) async {
    try {
      await _firestore.collection(_collection).doc(documentId).delete();
      
      if (kDebugMode) {
        debugPrint('Appointment deleted: $documentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting appointment: $e');
      }
      throw Exception('Failed to delete appointment: $e');
    }
  }

  static Stream<QuerySnapshot> getAppointmentsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('date', descending: false)
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting appointments: $e');
      }
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getAppointment(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting appointment: $e');
      }
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('date', isGreaterThan: now.subtract(const Duration(days: 1)).toIso8601String())
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting upcoming appointments: $e');
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPastAppointments() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('date', isLessThan: now.subtract(const Duration(days: 1)).toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting past appointments: $e');
      }
      return [];
    }
  }
}