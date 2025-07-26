import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dqxypwaxs';
  static String get _apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '492323429775172';
  static String get _apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? 'QQ6W2gO8fewKPN40GgMgTQxle4o';

  static String get _folder => dotenv.env['CLOUDINARY_FOLDER'] ?? 'finalapp/patients';

  static Future<void> initialize() async {
    if (kDebugMode) {
      print('Cloudinary initialized with cloud: $_cloudName');
    }
  }

  static Future<Map<String, String>> uploadFile(PlatformFile file) async {
    try {
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
      
      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ));
      }
      
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode != 200) {
        throw Exception('Upload failed: ${responseData.body}');
      }

      final data = jsonDecode(responseData.body);
      return {
        'url': data['secure_url'],
        'publicId': data['public_id'],
      };
    } catch (e) {
      throw Exception('Cloudinary upload error: $e');
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