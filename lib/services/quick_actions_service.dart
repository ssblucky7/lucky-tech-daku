import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finalapp/services/cloudinary_service.dart';

class QuickActionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _uploadsCollection = 'caresync_uploads';
  static const String _scansCollection = 'caresync_scans';
  static const String _qrCodesCollection = 'caresync_qr_codes';
  static const String _sharedProfilesCollection = 'caresync_shared_profiles';

  // Upload file
  static Future<String> uploadFile({
    required PlatformFile file,
    required String category,
    String? description,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_uploadsCollection).doc();
      
      // Upload file to Cloudinary
      final uploadResult = await CloudinaryService.uploadFile(file);
      
      if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
        final uploadData = {
          'id': docRef.id,
          'user_id': userId,
          'file_name': file.name,
          'file_size': file.size,
          'file_type': file.extension ?? 'unknown',
          'category': category,
          'description': description ?? '',
          'file_url': uploadResult['url'],
          'public_id': uploadResult['public_id'],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        await docRef.set(uploadData);
        
        if (kDebugMode) {
          debugPrint('File uploaded: ${docRef.id}');
        }
        
        return docRef.id;
      } else {
        throw Exception('Failed to upload file to cloud storage');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading file: $e');
      }
      throw Exception('Failed to upload file: $e');
    }
  }

  // Save scan result
  static Future<String> saveScanResult({
    required String scanType,
    required String content,
    PlatformFile? scannedImage,
    Map<String, dynamic>? extractedData,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_scansCollection).doc();
      
      String? imageUrl;
      String? publicId;
      
      // Upload scanned image to Cloudinary if provided
      if (scannedImage != null) {
        final uploadResult = await CloudinaryService.uploadFile(scannedImage);
        
        if (uploadResult.containsKey('success') && uploadResult['success'].toString() == 'true') {
          imageUrl = uploadResult['url'];
          publicId = uploadResult['public_id'];
        }
      }

      final scanData = {
        'id': docRef.id,
        'user_id': userId,
        'scan_type': scanType,
        'content': content,
        'extracted_data': extractedData ?? {},
        'image_url': imageUrl,
        'public_id': publicId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(scanData);
      
      if (kDebugMode) {
        debugPrint('Scan result saved: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving scan result: $e');
      }
      throw Exception('Failed to save scan result: $e');
    }
  }

  // Generate and save QR code
  static Future<String> generateQRCode({
    required String content,
    required String qrType,
    String? title,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_qrCodesCollection).doc();
      
      final qrData = {
        'id': docRef.id,
        'user_id': userId,
        'content': content,
        'qr_type': qrType,
        'title': title ?? 'QR Code',
        'is_active': true,
        'scan_count': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(qrData);
      
      if (kDebugMode) {
        debugPrint('QR code generated: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating QR code: $e');
      }
      throw Exception('Failed to generate QR code: $e');
    }
  }

  // Create shared profile
  static Future<String> createSharedProfile({
    required Map<String, dynamic> profileData,
    String? customMessage,
    DateTime? expiryDate,
  }) async {
    try {
      String userId = 'default_user';
      final user = _auth.currentUser;
      if (user != null) {
        userId = user.uid;
      }

      final docRef = _firestore.collection(_sharedProfilesCollection).doc();
      
      final shareData = {
        'id': docRef.id,
        'user_id': userId,
        'profile_data': profileData,
        'custom_message': customMessage ?? '',
        'share_link': 'https://caresync.app/profile/${docRef.id}',
        'expiry_date': expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        'is_active': true,
        'view_count': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(shareData);
      
      if (kDebugMode) {
        debugPrint('Shared profile created: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating shared profile: $e');
      }
      throw Exception('Failed to create shared profile: $e');
    }
  }

  // Get uploads
  static Future<List<Map<String, dynamic>>> getUploads() async {
    try {
      final snapshot = await _firestore
          .collection(_uploadsCollection)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} uploads');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting uploads: $e');
      }
      return [];
    }
  }

  // Get scans
  static Future<List<Map<String, dynamic>>> getScans() async {
    try {
      final snapshot = await _firestore
          .collection(_scansCollection)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} scans');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting scans: $e');
      }
      return [];
    }
  }

  // Get QR codes
  static Future<List<Map<String, dynamic>>> getQRCodes() async {
    try {
      final snapshot = await _firestore
          .collection(_qrCodesCollection)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} QR codes');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting QR codes: $e');
      }
      return [];
    }
  }

  // Get shared profiles
  static Future<List<Map<String, dynamic>>> getSharedProfiles() async {
    try {
      final snapshot = await _firestore
          .collection(_sharedProfilesCollection)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      if (kDebugMode) {
        debugPrint('Found ${snapshot.docs.length} shared profiles');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting shared profiles: $e');
      }
      return [];
    }
  }

  // Delete upload
  static Future<void> deleteUpload(String uploadId) async {
    try {
      final doc = await _firestore.collection(_uploadsCollection).doc(uploadId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        // Delete file from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        // Delete document from Firestore
        await _firestore.collection(_uploadsCollection).doc(uploadId).delete();
        
        if (kDebugMode) {
          debugPrint('Upload deleted: $uploadId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting upload: $e');
      }
      throw Exception('Failed to delete upload: $e');
    }
  }

  // Delete scan
  static Future<void> deleteScan(String scanId) async {
    try {
      final doc = await _firestore.collection(_scansCollection).doc(scanId).get();
      
      if (doc.exists) {
        final data = doc.data();
        final publicId = data?['public_id'] as String?;
        
        // Delete image from Cloudinary if exists
        if (publicId != null) {
          await CloudinaryService.deleteFile(publicId);
        }
        
        // Delete document from Firestore
        await _firestore.collection(_scansCollection).doc(scanId).delete();
        
        if (kDebugMode) {
          debugPrint('Scan deleted: $scanId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting scan: $e');
      }
      throw Exception('Failed to delete scan: $e');
    }
  }

  // Update QR code scan count
  static Future<void> incrementQRScanCount(String qrCodeId) async {
    try {
      await _firestore.collection(_qrCodesCollection).doc(qrCodeId).update({
        'scan_count': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating QR scan count: $e');
      }
    }
  }

  // Update shared profile view count
  static Future<void> incrementProfileViewCount(String profileId) async {
    try {
      await _firestore.collection(_sharedProfilesCollection).doc(profileId).update({
        'view_count': FieldValue.increment(1),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating profile view count: $e');
      }
    }
  }
}