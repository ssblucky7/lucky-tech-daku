
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:finalapp/services/database_service.dart';
import 'package:finalapp/services/auth_persistence_service.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  // Initialize Firebase services (Firebase core already initialized in main)
  static Future<void> initialize() async {
    try {
      // Enable offline persistence for Firestore
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      if (kDebugMode) debugPrint('Firebase services initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase services initialization error: $e');
      // Don't rethrow to prevent app from crashing
    }
  }
  
  // Authentication methods
  static Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(email: email, password: password);
    await AuthPersistenceService.saveLoginState(credential.user!);
    return credential;
  }
  
  static Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
    await AuthPersistenceService.saveLoginState(credential.user!);
    return credential;
  }
  
  static Future<void> signOut() async {
    await AuthPersistenceService.clearLoginState();
    
    // Sign out from Firebase
    await auth.signOut();
    
    // Force app restart by clearing all navigation
    // The AuthWrapper will detect the cleared state and show login
  }
  
  // Check if user is logged in
  static bool isUserLoggedIn() {
    return auth.currentUser != null;
  }
  
  static User? get currentUser => auth.currentUser;
  
  static Stream<User?> get authStateChanges => auth.authStateChanges();
  
  // Initialize database when user signs in
  static Future<UserCredential> signInWithEmailAndPasswordAndInit(String email, String password) async {
    final credential = await signInWithEmailAndPassword(email, password);
    await DatabaseService.initializeDatabase();
    return credential;
  }
  
  static Future<UserCredential> createUserWithEmailAndPasswordAndInit(String email, String password) async {
    final credential = await createUserWithEmailAndPassword(email, password);
    await DatabaseService.initializeDatabase();
    return credential;
  }
  
  // Check persistent login state
  static Future<bool> checkPersistentLoginState() async {
    return await AuthPersistenceService.isLoggedIn();
  }
  
  // Firestore helper methods
  static CollectionReference collection(String path) {
    return firestore.collection(path);
  }
  
  static DocumentReference document(String path) {
    return firestore.doc(path);
  }
  
  // Real-time listeners
  static Stream<QuerySnapshot> getCollectionStream(String collection, {
    String? orderBy,
    bool descending = false,
    String? whereField,
    dynamic whereValue,
  }) {
    Query query = firestore.collection(collection);
    
    if (whereField != null && whereValue != null) {
      query = query.where(whereField, isEqualTo: whereValue);
    }
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    return query.snapshots();
  }
  
  // Batch operations
  static WriteBatch batch() {
    return firestore.batch();
  }
  
  static Future<void> commitBatch(WriteBatch batch) async {
    await batch.commit();
  }
}