import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';
import 'package:finalapp/models/data_models.dart';

class ReportsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'caresync_medical_reports';

  // Create a new medical report
  static Future<String> createReport({
    required String title,
    required String patient,
    required String doctor,
    required String category,
    required String summary,
    required String recommendations,
    String type = 'report',
    PlatformFile? file,
  }) async {
    try {
      // Use a default user ID if not authenticated
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_collection).doc();
      
      String? fileUrl;
      String? fileName;
      String? publicId;
      
      // Upload file to Cloudinary if provided
      if (file != null) {
        final uploadResult = await CloudinaryService.uploadFile(file);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          fileUrl = uploadResult['url'];
          fileName = file.name;
          publicId = uploadResult['public_id'];
        }
      }

      final reportData = {
        'id': docRef.id,
        'user_id': userId,
        'title': title,
        'patient': patient,
        'doctor': doctor,
        'date': FieldValue.serverTimestamp(),
        'category': category,
        'status': 'Completed',
        'summary': summary,
        'recommendations': recommendations,
        'attachments': file != null ? 1 : 0,
        'type': type,
        'file_url': fileUrl,
        'file_name': fileName,
        'public_id': publicId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(reportData);
      
      if (kDebugMode) {
        debugPrint('Report created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating report: $e');
      }
      throw Exception('Failed to create report: $e');
    }
  }

  // Get all reports for current user
  static Stream<QuerySnapshot> getReportsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Get reports as list
  static Future<List<Report>> getReports() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} reports in collection');
      }

      return snapshot.docs.map((doc) {
        if (kDebugMode) {
          debugPrint('Report data: ${doc.data()}');
        }
        return Report.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting reports: $e');
      }
      return [];
    }
  }

  // Update report
  static Future<void> updateReport({
    required String documentId,
    String? title,
    String? patient,
    String? doctor,
    String? category,
    String? summary,
    String? recommendations,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (patient != null) updateData['patient'] = patient;
      if (doctor != null) updateData['doctor'] = doctor;
      if (category != null) updateData['category'] = category;
      if (summary != null) updateData['summary'] = summary;
      if (recommendations != null) updateData['recommendations'] = recommendations;
      if (status != null) updateData['status'] = status;

      await _firestore.collection(_collection).doc(documentId).update(updateData);
      
      if (kDebugMode) {
        debugPrint('Report updated: $documentId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating report: $e');
      }
      throw Exception('Failed to update report: $e');
    }
  }

  // Delete report
  static Future<void> deleteReport(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        // Delete file from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        // Delete document from Firestore
        await _firestore.collection(_collection).doc(documentId).delete();
        
        if (kDebugMode) {
          debugPrint('Report deleted: $documentId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting report: $e');
      }
      throw Exception('Failed to delete report: $e');
    }
  }

  // Get single report
  static Future<Report?> getReport(String documentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(documentId).get();
      
      if (doc.exists) {
        return Report.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting report: $e');
      }
      return null;
    }
  }

  // Search reports
  static Future<List<Report>> searchReports(String query) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: user.uid)
          .get();

      final reports = snapshot.docs.map((doc) {
        return Report.fromMap(doc.data(), doc.id);
      }).toList();

      // Filter by query
      return reports.where((report) {
        return report.title.toLowerCase().contains(query.toLowerCase()) ||
               report.patient.toLowerCase().contains(query.toLowerCase()) ||
               report.doctor.toLowerCase().contains(query.toLowerCase()) ||
               report.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching reports: $e');
      }
      return [];
    }
  }

  // Filter reports by category
  static Future<List<Report>> getReportsByCategory(String category) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: user.uid)
          .where('category', isEqualTo: category)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Report.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting reports by category: $e');
      }
      return [];
    }
  }

  // Get reports by date range
  static Future<List<Report>> getReportsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection(_collection)
          .where('user_id', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Report.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting reports by date range: $e');
      }
      return [];
    }
  }
}