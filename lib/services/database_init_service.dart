import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseInitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeCollections() async {
    try {
      // Create initial collections with sample data to ensure they exist
      await _createPatientsCollection();
      await _createAppointmentsCollection();
      await _createUsersCollection();
      await _createFamilyMembersCollection();
      await _createMedicationsCollection();
      
      if (kDebugMode) {
        debugPrint('Database collections initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing database collections: $e');
      }
    }
  }

  static Future<void> _createPatientsCollection() async {
    try {
      final collection = _firestore.collection('patients');
      final snapshot = await collection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Create a sample patient document to initialize the collection
        await collection.add({
          'patientId': 'SAMPLE001',
          'name': 'Sample Patient',
          'age': 30,
          'condition': 'Sample Condition',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'type': 'sample',
        });
        
        if (kDebugMode) {
          debugPrint('Patients collection created with sample data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating patients collection: $e');
      }
    }
  }

  static Future<void> _createAppointmentsCollection() async {
    try {
      final collection = _firestore.collection('appointments');
      final snapshot = await collection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Create a sample appointment document
        await collection.add({
          'appointmentId': 'APPT001',
          'patient': 'Sample Patient',
          'doctor': 'Dr. Sample',
          'specialty': 'General',
          'date': DateTime.now().toIso8601String(),
          'time': '10:00',
          'status': 'pending',
          'symptoms': 'Sample symptoms',
          'notes': '',
          'createdAt': DateTime.now().toIso8601String(),
          'type': 'sample',
        });
        
        if (kDebugMode) {
          debugPrint('Appointments collection created with sample data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating appointments collection: $e');
      }
    }
  }

  static Future<void> _createUsersCollection() async {
    try {
      final collection = _firestore.collection('users');
      final snapshot = await collection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Create a sample user document
        await collection.add({
          'userId': 'USER001',
          'name': 'Sample User',
          'email': 'sample@example.com',
          'role': 'patient',
          'createdAt': DateTime.now().toIso8601String(),
          'type': 'sample',
        });
        
        if (kDebugMode) {
          debugPrint('Users collection created with sample data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating users collection: $e');
      }
    }
  }

  static Future<void> _createFamilyMembersCollection() async {
    try {
      final collection = _firestore.collection('family_members');
      final snapshot = await collection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Create a sample family member document
        await collection.add({
          'memberId': 'FM001',
          'name': 'Sample Member',
          'relation': 'Self',
          'age': 30,
          'bloodGroup': 'O+',
          'phone': '',
          'email': '',
          'address': '',
          'emergencyContact': '',
          'healthRecords': {
            'lastCheckup': '',
            'bloodPressure': '',
            'bloodSugar': '',
            'allergies': '',
            'medications': '',
            'conditions': '',
          },
          'createdAt': DateTime.now().toIso8601String(),
          'type': 'sample',
        });
        
        if (kDebugMode) {
          debugPrint('Family members collection created with sample data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating family members collection: $e');
      }
    }
  }

  static Future<void> _createMedicationsCollection() async {
    try {
      final collection = _firestore.collection('medications');
      final snapshot = await collection.limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Create a sample medication document
        await collection.add({
          'medicationId': 'MED001',
          'medicationName': 'Sample Medicine',
          'dosage': '500mg',
          'frequency': 'Daily',
          'time': '9:00 AM',
          'medicationType': 'Tablet',
          'notes': 'Take with food',
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'type': 'sample',
        });
        
        if (kDebugMode) {
          debugPrint('Medications collection created with sample data');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating medications collection: $e');
      }
    }
  }

  static Future<void> cleanupSampleData() async {
    try {
      // Remove sample data after real data is added
      final collections = ['patients', 'appointments', 'users', 'family_members', 'medications'];
      
      for (final collectionName in collections) {
        final snapshot = await _firestore
            .collection(collectionName)
            .where('type', isEqualTo: 'sample')
            .get();
        
        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
      
      if (kDebugMode) {
        debugPrint('Sample data cleaned up successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cleaning up sample data: $e');
      }
    }
  }
}