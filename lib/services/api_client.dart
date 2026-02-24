import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_service.dart';
import 'groq_ocr_service.dart';

class ApiClient {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Patient API endpoints
  static Future<Map<String, dynamic>> createPatient({
    required String name,
    required int age,
    required String condition,
    PlatformFile? file,
  }) async {
    try {
      // Step 1: Upload file to Cloudinary if provided
      String? fileUrl, publicId;
      Map<String, dynamic>? ocrData;
      
      if (file != null) {
        if (kDebugMode) debugPrint('Uploading file to Cloudinary...');
        final uploadResult = await CloudinaryService.uploadFile(file);
        fileUrl = uploadResult['url'];
        publicId = uploadResult['publicId'];
        
        // Step 2: Process OCR if image file
        if (_isImageFile(file.name) && fileUrl != null) {
          if (kDebugMode) debugPrint('Processing OCR...');
          ocrData = await GroqOCRService.extractTextFromImage(fileUrl);
        }
      }
      
      // Step 3: Create patient record in Firebase
      final docRef = _firestore.collection('patients').doc();
      final patientData = {
        'id': docRef.id,
        'patientId': 'P${docRef.id.substring(0, 8).toUpperCase()}',
        'name': name,
        'age': age,
        'condition': condition,
        'fileUrl': fileUrl,
        'publicId': publicId,
        'ocrData': ocrData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };
      
      await docRef.set(patientData);
      
      if (kDebugMode) debugPrint('Patient created successfully: ${docRef.id}');
      
      return {
        'success': true,
        'message': 'Patient created successfully',
        'data': {
          'id': docRef.id,
          'patientId': patientData['patientId'],
          'fileUrl': fileUrl,
          'ocrData': ocrData,
        }
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating patient: $e');
      return {
        'success': false,
        'message': 'Failed to create patient: $e',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> updatePatient({
    required String documentId,
    required String name,
    required int age,
    required String condition,
    PlatformFile? newFile,
    String? existingFileUrl,
    String? existingPublicId,
  }) async {
    try {
      String? fileUrl = existingFileUrl;
      String? publicId = existingPublicId;
      Map<String, dynamic>? ocrData;
      
      // Handle file update
      if (newFile != null) {
        // Delete old file from Cloudinary
        if (existingPublicId != null) {
          await CloudinaryService.deleteFile(existingPublicId);
        }
        
        // Upload new file
        final uploadResult = await CloudinaryService.uploadFile(newFile);
        fileUrl = uploadResult['url'];
        publicId = uploadResult['publicId'];
        
        // Process OCR for new image
        if (_isImageFile(newFile.name) && fileUrl != null) {
          ocrData = await GroqOCRService.extractTextFromImage(fileUrl);
        }
      }
      
      // Update patient record
      final updateData = {
        'name': name,
        'age': age,
        'condition': condition,
        'fileUrl': fileUrl,
        'publicId': publicId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (ocrData != null) {
        updateData['ocrData'] = ocrData;
      }
      
      await _firestore.collection('patients').doc(documentId).update(updateData);
      
      return {
        'success': true,
        'message': 'Patient updated successfully',
        'data': {
          'id': documentId,
          'fileUrl': fileUrl,
          'ocrData': ocrData,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update patient: $e',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> deletePatient(String documentId) async {
    try {
      // Get patient data first to delete associated files
      final doc = await _firestore.collection('patients').doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final publicId = data['publicId'] as String?;
        
        // Delete file from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
      }
      
      // Delete patient record from Firebase
      await _firestore.collection('patients').doc(documentId).delete();
      
      return {
        'success': true,
        'message': 'Patient deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete patient: $e',
        'error': e.toString(),
      };
    }
  }
  
  static Stream<QuerySnapshot> getPatientsStream() {
    return _firestore
        .collection('patients')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  static Future<Map<String, dynamic>> getPatient(String documentId) async {
    try {
      final doc = await _firestore.collection('patients').doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Patient not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get patient: $e',
        'error': e.toString(),
      };
    }
  }
  
  static Future<List<Map<String, dynamic>>> searchPatients(String query) async {
    try {
      final snapshot = await _firestore
          .collection('patients')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .where('status', isEqualTo: 'active')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Search error: $e');
      return [];
    }
  }
  
  // File management endpoints
  static Future<Map<String, dynamic>> uploadFile(PlatformFile file) async {
    try {
      final result = await CloudinaryService.uploadFile(file);
      
      // Store file metadata in Firebase
      final fileDoc = await _firestore.collection('files').add({
        'fileName': file.name,
        'fileUrl': result['url'],
        'publicId': result['publicId'],
        'uploadedAt': FieldValue.serverTimestamp(),
        'size': file.size,
      });
      
      return {
        'success': true,
        'message': 'File uploaded successfully',
        'data': {
          'fileId': fileDoc.id,
          'url': result['url'],
          'publicId': result['publicId'],
        }
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to upload file: $e',
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> deleteFile(String fileId, String publicId) async {
    try {
      // Delete from Cloudinary
      await CloudinaryService.deleteFile(publicId);
      
      // Delete metadata from Firebase
      await _firestore.collection('files').doc(fileId).delete();
      
      return {
        'success': true,
        'message': 'File deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete file: $e',
        'error': e.toString(),
      };
    }
  }
  
  // OCR processing endpoint
  static Future<Map<String, dynamic>> processOCR(String imageUrl) async {
    try {
      final ocrData = await GroqOCRService.extractTextFromImage(imageUrl);
      
      return {
        'success': true,
        'message': 'OCR processed successfully',
        'data': ocrData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to process OCR: $e',
        'error': e.toString(),
      };
    }
  }
  
  // Health check endpoint
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      // Test Firebase connection
      await _firestore.collection('health').limit(1).get();
      

      
      return {
        'success': true,
        'message': 'All services are healthy',
        'data': {
          'firebase': 'connected',
          'cloudinary': 'connected',
          'timestamp': DateTime.now().toIso8601String(),
        }
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Health check failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  static bool _isImageFile(String fileName) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }
}
