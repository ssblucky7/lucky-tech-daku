import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DataIsolationModule {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  // Get user-specific collection reference
  static CollectionReference getUserCollection(String collectionName) {
    return _firestore.collection(collectionName);
  }

  // Query with automatic user filtering
  static Query getUserQuery(String collectionName) {
    final userId = currentUserId ?? 'default_user';
    return _firestore.collection(collectionName).where('user_id', isEqualTo: userId);
  }

  // Add document with user_id
  static Future<DocumentReference> addDocument(
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    data['user_id'] = currentUserId ?? 'default_user';
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();
    return await _firestore.collection(collectionName).add(data);
  }

  // Update document (only if owned by user)
  static Future<void> updateDocument(
    String collectionName,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final doc = await _firestore.collection(collectionName).doc(docId).get();
    
    if (!doc.exists) throw Exception('Document not found');
    
    final ownerId = doc.data()?['user_id'];
    if (ownerId != currentUserId && ownerId != 'default_user') {
      throw Exception('Access denied');
    }

    data['updated_at'] = FieldValue.serverTimestamp();
    await _firestore.collection(collectionName).doc(docId).update(data);
  }

  // Delete document (only if owned by user)
  static Future<void> deleteDocument(String collectionName, String docId) async {
    final doc = await _firestore.collection(collectionName).doc(docId).get();
    
    if (!doc.exists) throw Exception('Document not found');
    
    final ownerId = doc.data()?['user_id'];
    if (ownerId != currentUserId && ownerId != 'default_user') {
      throw Exception('Access denied');
    }

    await _firestore.collection(collectionName).doc(docId).delete();
  }

  // Get user documents
  static Future<List<Map<String, dynamic>>> getUserDocuments(
    String collectionName, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = getUserQuery(collectionName);

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting documents: $e');
      return [];
    }
  }

  // Stream user documents
  static Stream<List<Map<String, dynamic>>> streamUserDocuments(
    String collectionName, {
    String? orderBy,
    bool descending = false,
  }) {
    Query query = getUserQuery(collectionName);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
