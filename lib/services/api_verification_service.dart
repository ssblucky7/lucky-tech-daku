import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:finalapp/services/groq_service.dart';
import 'package:finalapp/services/firebase_service.dart';
import 'package:finalapp/services/cloudinary_service.dart';

class ApiVerificationService {
  static Future<Map<String, bool>> verifyAllApis() async {
    final results = <String, bool>{};
    
    // Verify Firebase
    results['firebase'] = await _verifyFirebase();
    
    // Verify Cloudinary
    results['cloudinary'] = _verifyCloudinary();
    
    // Verify Gemini AI
    results['groq'] = await _verifyGemini();
    
    if (kDebugMode) {
      debugPrint('=== API Verification Results ===');
      results.forEach((key, value) {
        debugPrint('$key: ${value ? "✅ OK" : "❌ FAILED"}');
      });
    }
    
    return results;
  }
  
  static Future<bool> _verifyFirebase() async {
    try {
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
      final apiKey = dotenv.env['FIREBASE_WEB_API_KEY'];
      
      if (projectId == null || projectId.isEmpty || apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) debugPrint('Firebase: Missing credentials');
        return false;
      }
      
      // Check if Firebase is initialized
      if (FirebaseService.firestore != null) {
        if (kDebugMode) debugPrint('Firebase: Initialized successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase verification error: $e');
      return false;
    }
  }
  
  static bool _verifyCloudinary() {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final apiKey = dotenv.env['CLOUDINARY_API_KEY'];
      final apiSecret = dotenv.env['CLOUDINARY_API_SECRET'];
      
      if (cloudName == null || cloudName.isEmpty ||
          apiKey == null || apiKey.isEmpty ||
          apiSecret == null || apiSecret.isEmpty) {
        if (kDebugMode) debugPrint('Cloudinary: Missing credentials');
        return false;
      }
      
      if (kDebugMode) debugPrint('Cloudinary: Credentials configured');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Cloudinary verification error: $e');
      return false;
    }
  }
  
  static Future<bool> _verifyGemini() async {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) debugPrint('Groq AI: Missing API key');
        return false;
      }
      
      // Test Groq connection
      final isWorking = await GroqService.testConnection();
      
      if (kDebugMode) {
        debugPrint('Groq AI: ${isWorking ? "API working" : "API test failed"}');
      }
      
      return isWorking;
    } catch (e) {
      if (kDebugMode) debugPrint('Groq AI verification error: $e');
      return false;
    }
  }
  
  static String getConfigurationStatus() {
    final firebase = dotenv.env['FIREBASE_PROJECT_ID']?.isNotEmpty ?? false;
    final cloudinary = dotenv.env['CLOUDINARY_CLOUD_NAME']?.isNotEmpty ?? false;
    final groq = dotenv.env['GROQ_API_KEY']?.isNotEmpty ?? false;
    
    if (firebase && cloudinary && groq) {
      return 'All APIs configured ✅';
    }
    
    final missing = <String>[];
    if (!firebase) missing.add('Firebase');
    if (!cloudinary) missing.add('Cloudinary');
    if (!groq) missing.add('Groq AI');
    
    return 'Missing: ${missing.join(", ")} ❌';
  }
}
