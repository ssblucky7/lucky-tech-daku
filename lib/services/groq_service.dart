import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get _model => dotenv.env['GROQ_MODEL'] ?? 'llama-3.3-70b-versatile';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> generateResponse({
    required String message,
    required String language,
    List<Map<String, String>>? context,
  }) async {
    if (_apiKey.isEmpty) {
      return 'Please configure your Groq API key in .env file';
    }
    
    try {
      final messages = <Map<String, String>>[];
      
      // Add system message for language
      messages.add({
        'role': 'system',
        'content': _getSystemPrompt(language),
      });
      
      // Add context if provided (filter out timestamp field)
      if (context != null && context.isNotEmpty) {
        messages.addAll(
          context.take(5).map((msg) => {
            'role': msg['role']!,
            'content': msg['content']!,
          }).toList(),
        );
      }
      
      // Add user message
      messages.add({
        'role': 'user',
        'content': message,
      });
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'messages': messages,
          'model': _model,
          'temperature': 0.9,
          'max_completion_tokens': 2048,
          'top_p': 1,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];
          return content ?? 'Sorry, I could not generate a response.';
        }
        return 'Sorry, I could not generate a response.';
      } else if (response.statusCode == 401) {
        if (kDebugMode) debugPrint('Groq API Error: Invalid API key');
        return 'API Error: Invalid API key. Please check your GROQ_API_KEY in .env file.';
      } else if (response.statusCode == 429) {
        if (kDebugMode) debugPrint('Groq API Error: Rate limit exceeded');
        return 'API Error: Rate limit exceeded. Please try again in a moment.';
      } else {
        if (kDebugMode) {
          debugPrint('Groq API Error: ${response.statusCode}');
          debugPrint('Response body: ${response.body}');
        }
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        return 'API Error: $errorMessage';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Groq Service Error: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  static String _getSystemPrompt(String language) {
    switch (language) {
      case 'ne':
        return 'तपाईं एक सहयोगी स्वास्थ्य सहायक हुनुहुन्छ। नेपालीमा जवाफ दिनुहोस्। सहयोगी, सटीक र वार्तालापमूलक हुनुहोस्।';
      case 'hi':
        return 'आप एक सहायक स्वास्थ्य सहायक हैं। हिंदी में जवाब दें। सहायक, सटीक और बातचीत के अनुकूल रहें।';
      default:
        return 'You are a helpful health assistant. Respond in English. Be helpful, accurate, and conversational.';
    }
  }

  static String getWelcomeMessage(String language) {
    switch (language) {
      case 'ne':
        return 'नमस्कार! म तपाईंको AI स्वास्थ्य सहायक हुँ। आज म तपाईंलाई कसरी सहायता गर्न सक्छु?';
      case 'hi':
        return 'नमस्ते! मैं आपका AI स्वास्थ्य सहायक हूँ। आज मैं आपकी कैसे सहायता कर सकता हूँ?';
      default:
        return 'Hello! I\'m your AI health assistant. How can I help you today?';
    }
  }

  static String detectLanguage(String text) {
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      if (text.contains('छ') || text.contains('हुन्छ') || text.contains('गर्छ')) {
        return 'ne';
      }
      return 'hi';
    }
    return 'en';
  }

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