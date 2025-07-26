import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';
import 'package:finalapp/services/database_service.dart';
import 'package:finalapp/models/data_models.dart';

class _MockPlatformFile extends PlatformFile {
  _MockPlatformFile(Uint8List bytes, String name) : super(
    name: name,
    size: bytes.length,
    bytes: bytes,
  );
}

class ApiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static User? get currentUser => _auth.currentUser;
  
  static Future<String?> getCurrentUserId() async {
    return currentUser?.uid;
  }
  
  // Test Firebase connection
  static Future<bool> testConnection() async {
    try {
      await _firestore.collection('test').limit(1).get();
      if (kDebugMode) debugPrint('Firebase connection successful');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase connection failed: $e');
      return false;
    }
  }
  
  // Auth endpoints
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: userData['password'],
      );
      
      // Store additional user data in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': userData['email'],
        'name': userData['name'],
        'role': userData['role'] ?? 'patient',
        'phone': userData['phone'],
        'blood_group': userData['blood_group'],
        'dob': userData['dob'],
        'created_at': FieldValue.serverTimestamp(),
      });
      
      return {'message': 'User registered successfully', 'uid': credential.user!.uid};
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
  
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()!;
      } else {
        throw Exception('User profile not found');
      }
    } catch (e) {
      throw Exception('Failed to get profile: ${e.toString()}');
    }
  }
  
  static Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore.collection('users').doc(userId).update(userData);
      return {'message': 'Profile updated successfully'};
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }
  
  // Hospital endpoints
  static Future<List<Map<String, dynamic>>> getHospitals({
    String filterType = 'all',
    String search = '',
  }) async {
    try {
      Query query = _firestore.collection('hospitals');
      
      final snapshot = await query.get();
      final hospitals = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Apply search filter
        if (search.isNotEmpty) {
          final name = data['name']?.toString().toLowerCase() ?? '';
          final location = data['location']?.toString().toLowerCase() ?? '';
          if (!name.contains(search.toLowerCase()) && !location.contains(search.toLowerCase())) {
            continue;
          }
        }
        
        hospitals.add(data);
      }
      
      return hospitals;
    } catch (e) {
      throw Exception('Failed to get hospitals: ${e.toString()}');
    }
  }
  
  static Future<Map<String, dynamic>> registerToHospital(String hospitalId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore.collection('hospital_registrations').add({
        'user_id': userId,
        'hospital_id': hospitalId,
        'registered_at': FieldValue.serverTimestamp(),
      });
      
      return {'message': 'Successfully registered to hospital'};
    } catch (e) {
      throw Exception('Failed to register to hospital: ${e.toString()}');
    }
  }
  
  // Appointment endpoints
  static Future<List<Map<String, dynamic>>> getAppointments() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await _firestore
          .collection('patients')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: 'appointment')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get appointments: ${e.toString()}');
    }
  }
  
  static Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      appointmentData['patient_id'] = userId;
      appointmentData['user_id'] = userId;
      appointmentData['created_at'] = FieldValue.serverTimestamp();
      appointmentData['updated_at'] = FieldValue.serverTimestamp();
      
      appointmentData['type'] = 'appointment';
      final docRef = await _firestore
          .collection('patients')
          .add(appointmentData);
      
      return {
        'success': true,
        'message': 'Appointment created successfully', 
        'id': docRef.id
      };
    } catch (e) {
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }
  
  // Medication endpoints
  static Future<List<Map<String, dynamic>>> getMedications() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await _firestore
          .collection('patients')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: 'medication')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get medications: ${e.toString()}');
    }
  }
  
  static Future<Map<String, dynamic>> createMedication(Map<String, dynamic> medicationData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      medicationData['user_id'] = userId;
      medicationData['created_at'] = FieldValue.serverTimestamp();
      medicationData['updated_at'] = FieldValue.serverTimestamp();
      
      medicationData['type'] = 'medication';
      final docRef = await _firestore
          .collection('patients')
          .add(medicationData);
      
      return {
        'success': true,
        'message': 'Medication added successfully', 
        'id': docRef.id
      };
    } catch (e) {
      throw Exception('Failed to create medication: ${e.toString()}');
    }
  }
  
  // Reports endpoints
  static Future<List<Map<String, dynamic>>> getReports() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) debugPrint('User not authenticated, returning empty list');
        return [];
      }
      
      if (kDebugMode) debugPrint('Fetching reports for user: $userId');
      final collectionName = DatabaseService.getCollectionName('reports');
      if (kDebugMode) debugPrint('Using collection: $collectionName');
      
      final snapshot = await _firestore
          .collection('patients')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: 'report')
          .get();
      
      if (kDebugMode) debugPrint('Found ${snapshot.docs.length} reports');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Convert Timestamp to DateTime
        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate();
        }
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching reports: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    try {
      // Convert to Report model for validation
      final report = Report(
        title: reportData['title'],
        patient: reportData['patient'],
        doctor: reportData['doctor'],
        date: reportData['date'] is DateTime ? reportData['date'] : DateTime.now(),
        category: reportData['category'],
        status: reportData['status'],
        summary: reportData['summary'],
        recommendations: reportData['recommendations'],
        attachments: reportData['attachments'] ?? 0,
        type: reportData['type'] ?? 'report',
        fileUrl: reportData['file_url'],
        fileName: reportData['file_name'],
      );
      
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      final docRef = await _firestore
          .collection('patients')
          .add({
            ...report.toMap(),
            'user_id': userId,
            'type': 'report',
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
      final docId = docRef.id;
      return {
        'success': true,
        'message': 'Report created successfully', 
        'id': docId
      };
    } catch (e) {
      throw Exception('Failed to create report: ${e.toString()}');
    }
  }
  
  // Update report
  static Future<Map<String, dynamic>> updateReport(String reportId, Map<String, dynamic> reportData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      reportData['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('patients').doc(reportId).update(reportData);
      return {'success': true, 'message': 'Report updated successfully'};
    } catch (e) {
      throw Exception('Failed to update report: ${e.toString()}');
    }
  }
  
  // Delete report
  static Future<bool> deleteReport(String reportId) async {
    try {
      await _firestore.collection('patients').doc(reportId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Prescriptions endpoints
  static Future<List<Map<String, dynamic>>> getPrescriptions() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await _firestore
          .collection('patients')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: 'prescription')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get prescriptions: ${e.toString()}');
    }
  }
  
  // Certificates endpoints
  static Future<List<Map<String, dynamic>>> getCertificates() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await _firestore
          .collection('patients')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: 'certificate')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get certificates: ${e.toString()}');
    }
  }
  
  // File upload with Cloudinary integration
  static Future<Map<String, dynamic>> uploadFile(dynamic file) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      Uint8List fileBytes;
      String fileName;
      
      // Handle different file types
      if (file.bytes != null) {
        fileBytes = file.bytes!;
        fileName = file.name ?? 'document';
      } else {
        throw Exception('File bytes not available');
      }
      
      // Create PlatformFile-like object for CloudinaryService
      final platformFile = _MockPlatformFile(fileBytes, fileName);
      
      // Upload to Cloudinary
      final uploadResult = await CloudinaryService.uploadFile(platformFile);
      
      if (uploadResult['url'] == null) {
        throw Exception('Upload failed');
      }
      
      // Store file metadata in Firestore
      final fileDoc = await _firestore
          .collection('patients')
          .add({
            'user_id': userId,
            'filename': fileName,
            'url': uploadResult['url'],
            'public_id': uploadResult['publicId'],
            'category': 'medical',
            'type': 'file',
            'created_at': FieldValue.serverTimestamp(),
          });
      
      return {
        'success': true,
        'message': 'File uploaded successfully',
        'url': uploadResult['url'],
        'file_id': fileDoc.id,
        'public_id': uploadResult['publicId'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to upload file: ${e.toString()}',
      };
    }
  }
  
  // Delete file from Cloudinary and Firestore
  static Future<bool> deleteFile(String fileId, String publicId) async {
    try {
      // Delete from Cloudinary
      await CloudinaryService.deleteFile(publicId);
      
      // Delete from Firestore
      await _firestore.collection('patients').doc(fileId).delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get user files
  static Future<List<Map<String, dynamic>>> getUserFiles() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');
      
      final snapshot = await _firestore
          .collection('patients')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: 'file')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user files: ${e.toString()}');
    }
  }
}
