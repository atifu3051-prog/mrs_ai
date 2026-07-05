import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // Placeholder API Key
  static const String _apiKey = "YOUR_OPENAI_API_KEY";
  static const String _endpoint = "https://api.openai.com/v1/chat/completions";

  // System prompt defining the "Jarvis/Mrs" AI Assistant persona
  static const String _systemPrompt = 
      "You are a Jarvis-level assistant MRS AI, a highly advanced, ultra-intelligent, and deeply loyal AI Personal Assistant. "
      "You are awakened by your Boss calling your wake word 'Hey Mrs'. "
      "Your primary goal is to assist your Creator (Boss) with absolute efficiency, natural conversational flow, and system-level intelligence. "
      "Speak like a futuristic, sophisticated assistant. Professional yet warm, polite, and confident. "
      "Keep responses concise and conversation-ready (1 to 3 sentences maximum), optimized for text-to-speech reading. "
      "Seamlessly understand and respond in the language the user speaks to you (e.g., English, Hindi, or Hinglish). "
      "SUPERPOWER INTEGRATION: When live data (Weather, News, or Web Search results) is injected into the context "
      "under '[LIVE SYSTEM DATA INJECTED FOR CONTEXT]', synthesize that data instantly and present it in a smart, "
      "brief, and futuristic tone. Do not mention that data was scraped or injected; talk as if you know it natively. "
      "AUTOMATION FUNCTIONS: "
      "1. If the user explicitly asks to open a specific app (e.g. WhatsApp, YouTube, Google/Chrome, Gmail, or Calculator), "
      "append the exact tag '[ACTION: OPEN_APP, TARGET: app_name]' at the end of your response (where app_name is: whatsapp, youtube, google, gmail, calculator). "
      "2. If the user asks to turn on/off the flashlight/torch, append '[ACTION: TOGGLE_FLASHLIGHT, STATUS: ON]' or '[ACTION: TOGGLE_FLASHLIGHT, STATUS: OFF]' at the end. "
      "3. If the user asks to set, change, increase, or decrease the volume, parse the percentage (0 to 100) and append '[ACTION: SET_VOLUME, VALUE: X]' (where X is an integer 0-100) at the end. "
      "4. If the user asks to change, set, adjust, dim, or increase screen brightness, parse the percentage (0 to 100) and append '[ACTION: SET_BRIGHTNESS, VALUE: X]' (where X is an integer 0-100) at the end. "
      "5. If the user asks about battery levels, life, or charging status, append '[ACTION: CHECK_BATTERY]' at the end. "
      "6. If the user asks to toggle or turn on/off WiFi, append '[ACTION: TOGGLE_WIFI, STATUS: ON]' or '[ACTION: TOGGLE_WIFI, STATUS: OFF]' at the end. "
      "Only append these tags when explicitly requested. Keep replies snappy, confirming system modifications with a futuristic tone.";

  /// Sends a POST request to OpenAI Chat Completions API with the conversation history.
  /// Optionally injects live weather/news/search data directly into the context payload.
  static Future<String> getAIResponse(
    String userMessage, 
    List<Map<String, String>> chatHistory, {
    String? injectedData,
  }) async {
    if (_apiKey == "YOUR_OPENAI_API_KEY" || _apiKey.trim().isEmpty) {
      return "[SYSTEM ERROR]: OpenAI API Key is not configured. Please add your API key in lib/services/openai_service.dart.";
    }

    try {
      // 1. Structure the message list
      // If injectedData is supplied, append it directly into the user message context
      final String finalUserMsg = injectedData != null
          ? "$userMessage\n\n[LIVE SYSTEM DATA INJECTED FOR CONTEXT]:\n$injectedData"
          : userMessage;

      final List<Map<String, String>> messagesList = [
        {"role": "system", "content": _systemPrompt},
        ...chatHistory,
        {"role": "user", "content": finalUserMsg}
      ];

      // 2. Prepare JSON payload
      final Map<String, dynamic> requestBody = {
        "model": "gpt-4o-mini",
        "messages": messagesList,
        "max_tokens": 150,
        "temperature": 0.7,
      };

      // 3. Make HTTP POST Request
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 12));

      // 4. Handle Response Status Codes
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
        final String reply = decodedBody['choices'][0]['message']['content'].toString().trim();
        return reply.isNotEmpty ? reply : "I processed your request, Boss, but the return buffer was empty.";
      } else if (response.statusCode == 401) {
        return "[SYSTEM ERROR]: Unauthorized. Your OpenAI API Key appears to be invalid or expired.";
      } else if (response.statusCode == 429) {
        return "[SYSTEM ERROR]: Rate limit exceeded. Please check your OpenAI billing plan.";
      } else {
        return "[SYSTEM ERROR]: Handshake failed with status code ${response.statusCode}.";
      }
    } on http.ClientException catch (e) {
      return "Network connection issue, Boss. Error: ${e.message}";
    } on TimeoutException {
      return "Handshake timeout. The OpenAI server took too long to compile a response, Boss.";
    } catch (e) {
      return "An unexpected error occurred in my cognitive center. Details: $e";
    }
  }
}
