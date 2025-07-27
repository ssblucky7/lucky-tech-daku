class ApiConfig {
  // Replace this with your actual Gemini API key
  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'YOUR_ACTUAL_GEMINI_API_KEY_HERE';
  
  // Instructions for getting API key:
  // 1. Go to https://makersuite.google.com/app/apikey
  // 2. Sign in with your Google account
  // 3. Click "Create API Key"
  // 4. Copy the generated key
  // 5. Replace the value above with your actual key
  
  static bool get isConfigured => geminiApiKey != 'YOUR_ACTUAL_GEMINI_API_KEY_HERE';
}