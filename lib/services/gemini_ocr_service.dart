import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiOCRService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyBi2qNZ8iLVUc-3pZKY-xa3BVMktmuO_J8';
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<Map<String, dynamic>> extractTextFromImage(String imageUrl) async {
    try {
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final base64Image = base64Encode(imageResponse.bodyBytes);
      final mimeType = _detectMimeType(imageUrl);

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [{
            'parts': [
              {
                'text': '''Extract medical information from this image and return ONLY a JSON object with this exact structure:
{
  "raw_text": "all text found in the image",
  "patient_info": {
    "name": "patient name if found",
    "age": age_number_if_found
  },
  "medical_data": {
    "condition": "medical condition if found"
  },
  "medications": ["list of medications found"],
  "dates": ["list of dates found"],
  "numbers": ["list of numbers found"]
}

Focus on extracting: patient names, ages, medical conditions, medications, dates, and vital signs. Return only the JSON, no other text.'''
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image
                }
              }
            ]
          }]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini API error: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'];
      
      if (candidates == null || candidates.isEmpty) {
        return _createEmptyResult('No response from Gemini AI');
      }

      final content = candidates[0]['content']['parts'][0]['text'];
      
      try {
        final jsonStart = content.indexOf('{');
        final jsonEnd = content.lastIndexOf('}') + 1;
        
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonString = content.substring(jsonStart, jsonEnd);
          final extractedData = jsonDecode(jsonString);
          extractedData['extracted_at'] = DateTime.now().toIso8601String();
          return Map<String, dynamic>.from(extractedData);
        }
      } catch (e) {
        // Fallback to raw content
      }
      
      return {
        'raw_text': content,
        'extracted_at': DateTime.now().toIso8601String(),
        'patient_info': <String, dynamic>{},
        'medical_data': <String, dynamic>{},
        'medications': <String>[],
        'dates': <String>[],
        'numbers': <String>[],
      };
    } catch (e) {
      return _createEmptyResult('OCR Error: $e', error: e.toString());
    }
  }

  static String _detectMimeType(String imageUrl) {
    final extension = imageUrl.toLowerCase().split('.').last;
    switch (extension) {
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      default: return 'image/jpeg';
    }
  }

  static Map<String, dynamic> _createEmptyResult(String message, {String? error}) {
    return {
      'raw_text': message,
      'extracted_at': DateTime.now().toIso8601String(),
      'patient_info': <String, dynamic>{},
      'medical_data': <String, dynamic>{},
      'medications': <String>[],
      'dates': <String>[],
      'numbers': <String>[],
      if (error != null) 'error': error,
    };
  }
}