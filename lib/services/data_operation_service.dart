import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:finalapp/services/activity_tracking_service.dart';
import 'package:finalapp/services/database_service.dart';

class DataOperationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  
  // Create document with activity tracking
  static Future<Map<String, dynamic>> createDocument({
    required String section,
    required Map<String, dynamic> data,
    String? description,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Add user ID and timestamps
      data['user_id'] = userId;
      data['created_at'] = FieldValue.serverTimestamp();
      data['updated_at'] = FieldValue.serverTimestamp();
      
      // Add section identifier
      data['section'] = section;
      
      // Get collection name
      final collectionName = DatabaseService.getCollectionName(section);
      
      // Create document
      final docRef = await _firestore.collection(collectionName).add(data);
      final docId = docRef.id;
      
      // Track activity
      await ActivityTrackingService.trackDataUpdate(
        section,
        docId,
        action: 'created',
      );
      
      if (kDebugMode) {
        debugPrint('Document created in $section with ID: $docId');
      }
      
      return {
        'success': true,
        'message': description ?? 'Document created successfully',
        'id': docId,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating document in $section: $e');
      }
      
      // Track error
      await ActivityTrackingService.trackError(
        'Failed to create document: ${e.toString()}',
        'DataOperationService.createDocument',
      );
      
      return {
        'success': false,
        'error': 'Failed to create document: ${e.toString()}',
      };
    }
  }
  
  // Update document with activity tracking
  static Future<Map<String, dynamic>> updateDocument({
    required String section,
    required String docId,
    required Map<String, dynamic> data,
    String? description,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Add updated timestamp
      data['updated_at'] = FieldValue.serverTimestamp();
      
      // Get collection name
      final collectionName = DatabaseService.getCollectionName(section);
      
      // Update document
      await _firestore.collection(collectionName).doc(docId).update(data);
      
      // Track activity
      await ActivityTrackingService.trackDataUpdate(
        section,
        docId,
        action: 'updated',
      );
      
      if (kDebugMode) {
        debugPrint('Document updated in $section with ID: $docId');
      }
      
      return {
        'success': true,
        'message': description ?? 'Document updated successfully',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating document in $section: $e');
      }
      
      // Track error
      await ActivityTrackingService.trackError(
        'Failed to update document: ${e.toString()}',
        'DataOperationService.updateDocument',
      );
      
      return {
        'success': false,
        'error': 'Failed to update document: ${e.toString()}',
      };
    }
  }
  
  // Delete document with activity tracking
  static Future<Map<String, dynamic>> deleteDocument({
    required String section,
    required String docId,
    String? description,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get collection name
      final collectionName = DatabaseService.getCollectionName(section);
      
      // Delete document
      await _firestore.collection(collectionName).doc(docId).delete();
      
      // Track activity
      await ActivityTrackingService.trackDataUpdate(
        section,
        docId,
        action: 'deleted',
      );
      
      if (kDebugMode) {
        debugPrint('Document deleted from $section with ID: $docId');
      }
      
      return {
        'success': true,
        'message': description ?? 'Document deleted successfully',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting document from $section: $e');
      }
      
      // Track error
      await ActivityTrackingService.trackError(
        'Failed to delete document: ${e.toString()}',
        'DataOperationService.deleteDocument',
      );
      
      return {
        'success': false,
        'error': 'Failed to delete document: ${e.toString()}',
      };
    }
  }
  
  // Get documents with query options
  static Future<List<Map<String, dynamic>>> getDocuments({
    required String section,
    String? orderBy,
    bool descending = true,
    int? limit,
    Map<String, dynamic>? whereConditions,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('User not authenticated, returning empty list');
        }
        return [];
      }
      
      // Get collection name
      final collectionName = DatabaseService.getCollectionName(section);
      
      // Start query
      Query query = _firestore.collection(collectionName);
      
      // Add user ID filter for user-specific collections
      if (section != 'hospitals') {
        query = query.where('user_id', isEqualTo: userId);
      }
      
      // Add where conditions if provided
      if (whereConditions != null) {
        whereConditions.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }
      
      // Add order by if provided
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // Add limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }
      
      // Execute query
      final snapshot = await query.get();
      
      // Track activity for significant data fetches
      if (section != 'user_activities') {
        await ActivityTrackingService.trackActivity(
          activityType: ActivityTrackingService.screenView,
          description: 'Fetched $section data',
          metadata: {
            'section': section,
            'count': snapshot.docs.length,
          },
        );
      }
      
      // Process results
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Convert Timestamps to DateTime
        _convertTimestamps(data);
        
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching documents from $section: $e');
      }
      
      // Track error
      await ActivityTrackingService.trackError(
        'Failed to fetch documents: ${e.toString()}',
        'DataOperationService.getDocuments',
      );
      
      return [];
    }
  }
  
  // Get document by ID
  static Future<Map<String, dynamic>?> getDocumentById({
    required String section,
    required String docId,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get collection name
      final collectionName = DatabaseService.getCollectionName(section);
      
      // Get document
      final doc = await _firestore.collection(collectionName).doc(docId).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data()!;
      data['id'] = doc.id;
      
      // Convert Timestamps to DateTime
      _convertTimestamps(data);
      
      return data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching document from $section: $e');
      }
      
      // Track error
      await ActivityTrackingService.trackError(
        'Failed to fetch document: ${e.toString()}',
        'DataOperationService.getDocumentById',
      );
      
      return null;
    }
  }
  
  // Helper method to convert Firestore Timestamps to DateTime
  static void _convertTimestamps(Map<String, dynamic> data) {
    final timestampFields = ['created_at', 'updated_at', 'date', 'timestamp'];
    
    for (final field in timestampFields) {
      if (data[field] is Timestamp) {
        data[field] = (data[field] as Timestamp).toDate();
      }
    }
  }
  
  // Batch operations with activity tracking
  static Future<Map<String, dynamic>> performBatchOperation({
    required List<Map<String, dynamic>> operations,
    required String description,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final batch = _firestore.batch();
      final operationDetails = <Map<String, dynamic>>[];
      
      for (final operation in operations) {
        final type = operation['type'] as String;
        final section = operation['section'] as String;
        final collectionName = DatabaseService.getCollectionName(section);
        
        switch (type) {
          case 'create':
            final data = operation['data'] as Map<String, dynamic>;
            data['user_id'] = userId;
            data['created_at'] = FieldValue.serverTimestamp();
            data['updated_at'] = FieldValue.serverTimestamp();
            data['section'] = section;
            
            final docRef = _firestore.collection(collectionName).doc();
            batch.set(docRef, data);
            
            operationDetails.add({
              'type': 'create',
              'section': section,
              'id': docRef.id,
            });
            break;
            
          case 'update':
            final docId = operation['id'] as String;
            final data = operation['data'] as Map<String, dynamic>;
            data['updated_at'] = FieldValue.serverTimestamp();
            
            final docRef = _firestore.collection(collectionName).doc(docId);
            batch.update(docRef, data);
            
            operationDetails.add({
              'type': 'update',
              'section': section,
              'id': docId,
            });
            break;
            
          case 'delete':
            final docId = operation['id'] as String;
            final docRef = _firestore.collection(collectionName).doc(docId);
            batch.delete(docRef);
            
            operationDetails.add({
              'type': 'delete',
              'section': section,
              'id': docId,
            });
            break;
        }
      }
      
      // Commit batch
      await batch.commit();
      
      // Track activity
      await ActivityTrackingService.trackActivity(
        activityType: ActivityTrackingService.dataUpdate,
        description: description,
        metadata: {
          'operations': operationDetails,
          'count': operationDetails.length,
        },
      );
      
      return {
        'success': true,
        'message': 'Batch operation completed successfully',
        'operations': operationDetails,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error performing batch operation: $e');
      }
      
      // Track error
      await ActivityTrackingService.trackError(
        'Failed to perform batch operation: ${e.toString()}',
        'DataOperationService.performBatchOperation',
      );
      
      return {
        'success': false,
        'error': 'Failed to perform batch operation: ${e.toString()}',
      };
    }
  }
}