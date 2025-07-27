import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<String> generateResponse({
    required String message,
    required String language,
    List<Map<String, String>>? context,
  }) async {
    if (_apiKey.isEmpty) {
      return 'Please configure your Gemini API key in .env file';
    }
    
    try {
      final prompt = _buildPrompt(message, language, context);
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.9,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 2048,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final text = candidate['content']['parts'][0]['text'];
            return text ?? 'Sorry, I could not generate a response.';
          }
        }
        return 'Sorry, I could not generate a response.';
      } else {
        if (kDebugMode) {
          debugPrint('Gemini API Error: ${response.statusCode}');
          debugPrint('Response body: ${response.body}');
        }
        return 'API Error: Please check your API key and try again.';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Gemini Service Error: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  static String _buildPrompt(String message, String language, List<Map<String, String>>? context) {
    final languageInstructions = {
      'en': 'Respond in English. Be helpful, accurate, and conversational.',
      'ne': 'नेपालीमा जवाफ दिनुहोस्। सहयोगी, सटीक र वार्तालापमूलक हुनुहोस्।',
      'hi': 'हिंदी में जवाब दें। सहायक, सटीक और बातचीत के अनुकूल रहें।',
    };

    String prompt = '${languageInstructions[language] ?? languageInstructions['en']}\n\n';
    
    if (context != null && context.isNotEmpty) {
      prompt += 'Previous conversation context:\n';
      for (final msg in context.take(5)) {
        prompt += '${msg['role']}: ${msg['content']}\n';
      }
      prompt += '\n';
    }
    
    prompt += 'User: $message\nAssistant:';
    return prompt;
  }

  static String getWelcomeMessage(String language) {
    switch (language) {
      case 'ne':
        return 'नमस्कार! म तपाईंको AI सहायक हुँ, अंग्रेजी, नेपाली र हिन्दीमा मद्दत गर्न तयार छु। आज म तपाईंलाई कसरी सहायता गर्न सक्छु?';
      case 'hi':
        return 'नमस्ते! मैं आपका AI सहायक हूँ, अंग्रेजी, नेपाली और हिंदी में मदद करने के लिए तैयार हूँ। आज मैं आपकी कैसे सहायता कर सकता हूँ?';
      default:
        return 'Hello! I\'m your AI assistant, ready to help in English, Nepali, or Hindi. How can I assist you today?';
    }
  }

  static String detectLanguage(String text) {
    // Simple language detection based on character patterns
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      // Check for specific Nepali words
      if (text.contains('छ') || text.contains('हुन्छ') || text.contains('गर्छ')) {
        return 'ne'; // Nepali
      }
      return 'hi'; // Hindi/Devanagari
    } else {
      return 'en'; // Default to English
    }
  }

  // Test method to verify API connection
  static Future<bool> testConnection() async {
    try {
      if (_apiKey.isEmpty) return false;
      final response = await generateResponse(
        message: 'Hello, can you respond with just "API Working"?',
        language: 'en',
      );
      return response.isNotEmpty && !response.contains('API Error') && !response.contains('Please configure');
    } catch (e) {
      if (kDebugMode) debugPrint('API test failed: $e');
      return false;
    }
  }
}