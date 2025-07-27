import 'package:flutter/foundation.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  // static final FlutterTts _tts = FlutterTts();
  // static final SpeechToText _stt = SpeechToText();

  static bool _isListening = false;
  static bool _isSpeaking = false;

  static Future<void> initialize() async {
    if (kDebugMode) debugPrint('Speech services disabled - dependencies not available');
  }

  static Future<void> speak(String text, String language) async {
    if (kDebugMode) debugPrint('TTS not available: $text');
  }

  static Future<void> pause() async {
    if (kDebugMode) debugPrint('TTS pause not available');
  }

  static Future<void> stop() async {
    _isSpeaking = false;
    if (kDebugMode) debugPrint('TTS stop not available');
  }

  static Future<String?> startListening(String language) async {
    if (kDebugMode) debugPrint('STT not available');
    return null;
  }

  static Future<void> stopListening() async {
    _isListening = false;
    if (kDebugMode) debugPrint('STT stop not available');
  }



  static bool get isListening => _isListening;
  static bool get isSpeaking => _isSpeaking;
}