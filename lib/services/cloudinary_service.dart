import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get _apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  static String get _folder => dotenv.env['CLOUDINARY_FOLDER'] ?? 'finalapp/patients';

  static Future<void> initialize() async {
    if (kDebugMode) {
      print('Cloudinary initialized with cloud: $_cloudName');
    }
  }

  static Future<Map<String, String>> uploadFile(PlatformFile file) async {
    try {
      if (_cloudName.isEmpty || _apiKey.isEmpty || _apiSecret.isEmpty) {
        throw Exception('Cloudinary credentials not configured');
      }
      
      if (file.bytes == null && file.path == null) {
        throw Exception('File has no data');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final publicId = 'patient_${timestamp}_${Random().nextInt(1000)}';
      
      final paramsToSign = 'folder=$_folder&public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(paramsToSign)).toString();
      
      final uploadType = file.name.toLowerCase().endsWith('.pdf') ? 'raw' : 'image';
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$uploadType/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['public_id'] = publicId
        ..fields['folder'] = _folder;
      
      if (kIsWeb || file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ));
      } else {
        throw Exception('No file data available');
      }
      
      if (kDebugMode) print('Uploading to Cloudinary: ${file.name}');
      
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode != 200) {
        if (kDebugMode) print('Cloudinary error: ${responseData.body}');
        throw Exception('Upload failed (${response.statusCode}): ${responseData.body}');
      }

      final data = jsonDecode(responseData.body);
      
      if (kDebugMode) print('Upload successful: ${data['secure_url']}');
      
      return {
        'url': data['secure_url'],
        'publicId': data['public_id'],
      };
    } catch (e) {
      if (kDebugMode) print('Cloudinary upload error: $e');
      throw Exception('Upload failed: $e');
    }
  }

  static Future<void> deleteFile(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final paramsToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(paramsToSign)).toString();
      
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
          'public_id': publicId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Delete failed: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('Cloudinary delete error: $e');
    }
  }
}