import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'cloudinary_service.dart';
import 'groq_ocr_service.dart';

class PatientService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'patients';

  static Future<String> createPatient({
    required String name,
    required int age,
    required String condition,
    PlatformFile? file,
  }) async {
    try {
      String? fileUrl, publicId;
      Map<String, dynamic>? ocrData;

      if (file != null) {
        final uploadResult = await CloudinaryService.uploadFile(file);
        fileUrl = uploadResult['url'];
        publicId = uploadResult['publicId'];

        if (_isImageFile(file.name)) {
          ocrData = await GroqOCRService.extractTextFromImage(fileUrl!);
        }
      }

      final docRef = _firestore.collection(_collection).doc();
      final patientData = {
        'patientId': 'P${docRef.id.substring(0, 8).toUpperCase()}',
        'name': name,
        'age': age,
        'condition': condition,
        'fileUrl': fileUrl,
        'publicId': publicId,
        'ocrData': ocrData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await docRef.set(patientData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create patient: $e');
    }
  }

  static Future<void> updatePatient({
    required String documentId,
    required String name,
    required int age,
    required String condition,
    PlatformFile? file,
    String? existingFileUrl,
    String? existingPublicId,
  }) async {
    try {
      String? fileUrl = existingFileUrl;
      String? publicId = existingPublicId;
      Map<String, dynamic>? ocrData;

      if (file != null) {
        if (existingPublicId != null) {
          await CloudinaryService.deleteFile(existingPublicId);
        }

        final uploadResult = await CloudinaryService.uploadFile(file);
        fileUrl = uploadResult['url'];
        publicId = uploadResult['publicId'];

        if (_isImageFile(file.name)) {
          ocrData = await GroqOCRService.extractTextFromImage(fileUrl!);
        }
      }

      final updateData = {
        'name': name,
        'age': age,
        'condition': condition,
        'fileUrl': fileUrl,
        'publicId': publicId,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (ocrData != null) {
        updateData['ocrData'] = ocrData;
      }

      await _firestore.collection(_collection).doc(documentId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  static Future<void> deletePatient(String documentId, {String? publicId}) async {
    try {
      if (publicId != null) {
        await CloudinaryService.deleteFile(publicId);
      }
      await _firestore.collection(_collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete patient: $e');
    }
  }

  static Stream<QuerySnapshot> getPatientsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<DocumentSnapshot> getPatient(String documentId) {
    return _firestore.collection(_collection).doc(documentId).get();
  }

  static Future<QuerySnapshot> searchPatients(String query) {
    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .get();
  }

  static bool _isImageFile(String fileName) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = fileName.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }
}