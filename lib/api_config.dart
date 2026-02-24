import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Groq AI key from .env file
  static String get geminiApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  
  // Firebase Configuration
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseApiKey => dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  
  // Cloudinary Configuration
  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  
  // Check if all APIs are configured
  static bool get isConfigured => 
      geminiApiKey.isNotEmpty && 
      firebaseProjectId.isNotEmpty && 
      cloudinaryCloudName.isNotEmpty;
}