import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:finalapp/services/activity_tracking_service.dart';

class MediaStorageService {
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  static String get folder => dotenv.env['CLOUDINARY_FOLDER'] ?? 'caresync';
  
  static bool get isConfigured => 
    cloudName.isNotEmpty && 
    apiKey.isNotEmpty && 
    apiSecret.isNotEmpty;
  
  // Initialize service
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      debugPrint('MediaStorageService initialized with cloud name: $cloudName');
    }
  }
  
  // Upload image file
  static Future<Map<String, dynamic>> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    required String userId,
    String category = 'profile',
    Map<String, String>? tags,
  }) async {
    return await _uploadFile(
      fileBytes: imageBytes,
      fileName: fileName,
      userId: userId,
      category: category,
      resourceType: 'image',
      tags: tags,
    );
  }
  
  // Upload document file
  static Future<Map<String, dynamic>> uploadDocument({
    required Uint8List documentBytes,
    required String fileName,
    required String userId,
    String category = 'medical',
    Map<String, String>? tags,
  }) async {
    return await _uploadFile(
      fileBytes: documentBytes,
      fileName: fileName,
      userId: userId,
      category: category,
      resourceType: 'raw',
      tags: tags,
    );
  }
  
  // Upload any file type
  static Future<Map<String, dynamic>> _uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    required String userId,
    required String category,
    required String resourceType,
    Map<String, String>? tags,
  }) async {
    try {
      if (!isConfigured) {
        throw Exception('Cloudinary is not properly configured');
      }
      
      // Create dynamic folder path
      final folderPath = '$folder/$category/$userId';
      
      // Generate unique public ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = '${category}_${timestamp}_${fileName.split('.').first}';
      
      // Prepare upload URL
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );
      
      // Add parameters
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = folderPath;
      request.fields['public_id'] = publicId;
      request.fields['resource_type'] = resourceType;
      
      // Add context metadata
      final context = {
        'user_id': userId,
        'category': category,
        'file_name': fileName,
      };
      
      // Add tags
      final tagList = <String>['user_$userId', category];
      if (tags != null) {
        tags.forEach((key, value) {
          tagList.add('${key}_$value');
          context[key] = value;
        });
      }
      
      request.fields['tags'] = tagList.join(',');
      request.fields['context'] = context.entries.map((e) => '${e.key}=${e.value}').join('|');
      
      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final result = jsonDecode(responseBody);
        
        // Track file upload activity
        await ActivityTrackingService.trackFileUpload(
          fileName,
          resourceType,
          fileBytes.length,
        );
        
        return {
          'success': true,
          'url': result['secure_url'],
          'public_id': result['public_id'],
          'format': result['format'] ?? fileName.split('.').last,
          'bytes': result['bytes'],
          'resource_type': resourceType,
          'folder': folderPath,
        };
      } else {
        if (kDebugMode) {
          debugPrint('Cloudinary upload failed: $responseBody');
        }
        
        // Track error
        await ActivityTrackingService.trackError(
          'Cloudinary upload failed: ${response.statusCode}',
          'MediaStorageService._uploadFile',
        );
        
        throw Exception('Upload failed: $responseBody');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading file to Cloudinary: $e');
      }
      
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  // Delete file from Cloudinary
  static Future<bool> deleteFile(String publicId, {String resourceType = 'image'}) async {
    try {
      if (!isConfigured) {
        throw Exception('Cloudinary is not properly configured');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);
      
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy');
      
      final response = await http.post(
        url,
        body: {
          'public_id': publicId,
          'signature': signature,
          'api_key': apiKey,
          'timestamp': timestamp,
        },
      );
      
      if (response.statusCode == 200) {
        // Track activity
        await ActivityTrackingService.trackDataUpdate(
          'media',
          publicId,
          action: 'deleted',
        );
        
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('Cloudinary delete failed: ${response.body}');
        }
        
        // Track error
        await ActivityTrackingService.trackError(
          'Cloudinary delete failed: ${response.statusCode}',
          'MediaStorageService.deleteFile',
        );
        
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting file from Cloudinary: $e');
      }
      
      return false;
    }
  }
  
  // Generate signature for API requests
  static String _generateSignature(String publicId, String timestamp) {
    final params = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final bytes = utf8.encode(params);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
  
  // Get file details
  static Future<Map<String, dynamic>> getFileDetails(String publicId, {String resourceType = 'image'}) async {
    try {
      if (!isConfigured) {
        throw Exception('Cloudinary is not properly configured');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);
      
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/explicit'
        '?public_id=$publicId'
        '&api_key=$apiKey'
        '&timestamp=$timestamp'
        '&signature=$signature'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          debugPrint('Cloudinary get details failed: ${response.body}');
        }
        
        return {'success': false, 'error': 'Failed to get file details'};
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting file details from Cloudinary: $e');
      }
      
      return {'success': false, 'error': e.toString()};
    }
  }
}