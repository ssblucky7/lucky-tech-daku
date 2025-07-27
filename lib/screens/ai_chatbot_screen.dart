import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finalapp/services/gemini_service.dart';
import 'package:finalapp/services/speech_service.dart';
import 'package:finalapp/widgets/tracked_screen.dart';
import 'package:finalapp/widgets/tracked_button.dart';
import 'dart:convert';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, String>> _messages = [];
  String _selectedLanguage = 'en';
  bool _isLoading = false;
  static const bool _isListening = false;
  String? _currentSpeakingMessage;

  final Map<String, String> _languages = {
    'en': 'English',
    'ne': 'नेपाली',
    'hi': 'हिंदी',
  };

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadChatHistory();
    _addWelcomeMessage();
    _testApiConnection();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    SpeechService.stop();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await SpeechService.initialize();
  }

  Future<void> _testApiConnection() async {
    final isWorking = await GeminiService.testConnection();
    if (!isWorking && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warning: AI service may not be working. Please check your API key.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('chat_history');
      final languageCode = prefs.getString('selected_language') ?? 'en';
      
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        setState(() {
          _messages = historyList.map((item) => Map<String, String>.from(item)).toList();
          _selectedLanguage = languageCode;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_history', json.encode(_messages));
      await prefs.setString('selected_language', _selectedLanguage);
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving chat history: $e');
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': GeminiService.getWelcomeMessage(_selectedLanguage),
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _isLoading = true;
    });

    _scrollToBottom();
    await _saveChatHistory();

    try {
      final response = await GeminiService.generateResponse(
        message: message,
        language: _selectedLanguage,
        context: _messages.take(_messages.length - 1).toList(),
      );

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _isLoading = false;
      });

      _scrollToBottom();
      await _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error. Please try again.',
          'timestamp': DateTime.now().toIso8601String(),
        });
        _isLoading = false;
      });
    }
  }

  void _startVoiceInput() {
    // Voice input disabled - dependencies not available
    if (kDebugMode) debugPrint('Voice input not available');
  }



  Future<void> _speakMessage(String message) async {
    if (_currentSpeakingMessage == message) {
      await SpeechService.stop();
      setState(() {
        _currentSpeakingMessage = null;
      });
    } else {
      await SpeechService.speak(message, _selectedLanguage);
      setState(() {
        _currentSpeakingMessage = message;
      });
    }
  }

  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to permanently delete all chat history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TrackedButton(
            buttonName: 'confirm_clear_history',
            screenName: 'ai_chatbot_screen',
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _messages.clear();
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      
      _addWelcomeMessage();
      await _saveChatHistory();
    }
  }

  void _sendMessageFromInput() {
    _sendMessage(_messageController.text);
    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TrackedScreen(
      screenName: 'ai_chatbot_screen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Assistant'),
          actions: [
            DropdownButton<String>(
              value: _selectedLanguage,
              icon: const Icon(Icons.language),
              underline: Container(),
              items: _languages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  _saveChatHistory();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearChatHistory,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingMessage();
                  }
                  
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? '';
    final isSpeaking = _currentSpeakingMessage == content;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isSpeaking ? Icons.stop : Icons.volume_up,
                            size: 16,
                            color: Colors.blue,
                          ),
                          onPressed: () => _speakMessage(content),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Thinking...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                _sendMessage(value);
                _messageController.clear();
              },
            ),
          ),
          const SizedBox(width: 8),
          TrackedButton(
            buttonName: 'voice_input',
            screenName: 'ai_chatbot_screen',
            onPressed: () => _startVoiceInput(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
          ),
          const SizedBox(width: 8),
          TrackedButton(
            buttonName: 'send_message',
            screenName: 'ai_chatbot_screen',
            onPressed: () => _sendMessageFromInput(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}