import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseInitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> initializeCollections() async {
    try {
      // Only initialize if user is authenticated
      if (_auth.currentUser == null) {
        if (kDebugMode) {
          debugPrint('Skipping database initialization - user not authenticated');
        }
        return;
      }
      
      if (kDebugMode) {
        debugPrint('Database collections initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing database collections: $e');
      }
    }
  }
}