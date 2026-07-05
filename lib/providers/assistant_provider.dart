import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message.dart';
import '../services/openai_service.dart';
import '../services/superpower_service.dart';

enum AssistantState {
  idle,
  listening,
  thinking,
  speaking,
  executing,
}

class AssistantProvider extends ChangeNotifier {
  AssistantState _state = AssistantState.idle;
  final List<Message> _messages = [];
  bool _isVoiceActive = false;

  // Voice Core Plugins
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Storage Core
  SharedPreferences? _prefs;
  String _userName = "Boss";
  
  bool _speechInitialized = false;
  String _lastWords = "";

  // Deep Hardware Controls
  final Battery _battery = Battery();

  // Timeout timers
  Timer? _vocalTimeoutTimer;

  // Getters
  AssistantState get state => _state;
  List<Message> get messages => List.unmodifiable(_messages);
  bool get isVoiceActive => _isVoiceActive;
  String get lastWords => _lastWords;
  String get userName => _userName;

  AssistantProvider() {
    _initPreferences();
    _initVoiceProtocols();
    _initBackgroundListener();
  }

  // --- LOCAL MEMORY INITIALIZATION ---
  Future<void> _initPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _userName = _prefs?.getString('user_name') ?? 'Boss';
      
      // Update welcome banner matching user settings
      _messages.add(
        Message(
          id: 'welcome',
          text: "Hello $_userName, I am MRS AI. Cognitive core v4.0 online. Tap the central reactor to speak, or write below.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to initialize local shared preferences database: $e");
      _messages.add(
        Message(
          id: 'welcome_fallback',
          text: "Hello Boss, I am MRS AI. Cognitive core online with fallback storage.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // Save/Update user identity dynamically
  Future<void> updateUserName(String newName) async {
    _userName = newName.trim().isEmpty ? 'Boss' : newName.trim();
    await _prefs?.setString('user_name', _userName);
    notifyListeners();
    
    _addSystemLog("Vocal registration modified. Master identity set to: $_userName");
    speak("Protocol acknowledged. I will address you as $_userName from now on.");
  }

  // --- VOICE PORT PROTOCOLS ---
  Future<void> _initVoiceProtocols() async {
    try {
      // Configure Speech-To-Text
      _speechInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );

      // Configure Text-To-Speech Event Hooks
      _flutterTts.setStartHandler(() {
        changeState(AssistantState.speaking);
      });
      _flutterTts.setCompletionHandler(() {
        changeState(AssistantState.idle);
      });
      _flutterTts.setErrorHandler((errorMsg) {
        debugPrint('TTS Error: $errorMsg');
        changeState(AssistantState.idle);
      });

      // Configure default English parameters
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setThemeValue(1.05); // Pacing rate slightly faster
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint("Failed to initialize voice hardware: $e");
    }
  }

  // --- BACKGROUND WAKE WORD SERVICE LISTENER ---
  void _initBackgroundListener() {
    try {
      FlutterBackgroundService().on('onWakeWordDetected').listen((event) {
        debugPrint("[UI Stream]: Background wake word detected.");
        _executeWakeWordActivation();
      });
    } catch (e) {
      debugPrint("Background wake word listener registration failed: $e");
    }
  }

  // Handle immediate transition when Boss says "Hey Mrs"
  Future<void> _executeWakeWordActivation() async {
    // 1. Play futuristic beep sound
    _playFuturisticBeep();

    // 2. Start audio capture immediately
    await startListening(fromWakeWord: true);
  }

  void _playFuturisticBeep() {
    _addSystemLog("Futuristic chime tone triggered.");
  }

  // Trigger 5-second timeout monitor for vocal commands
  void _startVocalTimeoutTimer() {
    _vocalTimeoutTimer?.cancel();
    _vocalTimeoutTimer = Timer(const Duration(seconds: 5), () async {
      if (_state == AssistantState.listening) {
        await _speechToText.stop();
        changeState(AssistantState.idle);
        _addSystemLog("Vocal intake timeout. No speech registered within 5 seconds.");
        _playTimeoutTone();
        speak("Intake link timeout. I am reverting back to background wake mode, Boss.");
      }
    });
  }

  void _playTimeoutTone() {
    _addSystemLog("Vocal timeout tone triggered.");
  }

  void changeState(AssistantState newState) {
    _state = newState;
    notifyListeners();
  }

  // --- SPEECH RECOGNITION (STT) ---
  Future<void> startListening({bool fromWakeWord = false}) async {
    if (_state != AssistantState.idle) return;

    if (!_speechInitialized) {
      _speechInitialized = await _speechToText.initialize();
    }

    if (_speechInitialized) {
      _lastWords = "";
      changeState(AssistantState.listening);

      // Start 5-second silence timeout if triggered by wake word
      if (fromWakeWord) {
        _startVocalTimeoutTimer();
      }
      
      await _speechToText.listen(
        onResult: (result) {
          // Cancel timeout as soon as speech signals start registering
          if (result.recognizedWords.isNotEmpty) {
            _vocalTimeoutTimer?.cancel();
          }

          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            stopListeningAndProcess(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
      notifyListeners();
    } else {
      _addSystemLog("WARNING: Microphone access blocked. Check Android Manifest configuration.");
    }
  }

  Future<void> stopListening() async {
    _vocalTimeoutTimer?.cancel();
    if (_state == AssistantState.listening) {
      await _speechToText.stop();
      changeState(AssistantState.idle);
    }
  }

  Future<void> stopListeningAndProcess(String userSpeech) async {
    _vocalTimeoutTimer?.cancel();
    await _speechToText.stop();
    changeState(AssistantState.idle);
    
    if (userSpeech.trim().isNotEmpty) {
      submitCommand(userSpeech);
    }
  }

  // --- TEXT TO SPEECH (TTS) ---
  Future<void> speak(String text) async {
    await _flutterTts.stop();
    
    // Clean out markdown blocks & system alerts for TTS output
    String vocalText = text
        .replaceAll(RegExp(r'(\[SYSTEM ERROR\]:|\[SYSTEM\]:|//)'), '')
        .replaceAll(RegExp(r'\[ACTION:[^\]]+\]'), '') 
        .trim();
        
    if (vocalText.isNotEmpty) {
      await _flutterTts.speak(vocalText);
    }
  }

  // --- PROCESS COGNITIVE COMMAND ---
  Future<void> submitCommand(String command) async {
    if (command.trim().isEmpty) return;

    // Stop TTS immediately if new command starts
    await _flutterTts.stop();

    // 1. Add User message bubble
    final userMsg = Message(
      id: DateTime.now().toString(),
      text: command,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();

    // 2. Transition to Thinking State
    changeState(AssistantState.thinking);
    
    // 3. Compile Chat History for API Context
    final List<Map<String, String>> apiHistory = _messages
        .where((m) => 
            m.id != 'welcome' && 
            m.id != 'welcome_fallback' && 
            m.id != 'welcome_reset' && 
            !m.text.startsWith('[SYSTEM]') &&
            !m.text.startsWith('[SYSTEM ERROR]'))
        .map((m) => {
              "role": m.isUser ? "user" : "assistant",
              "content": m.text,
            })
        .toList();

    if (apiHistory.isNotEmpty && apiHistory.last['content'] == command) {
      apiHistory.removeLast();
    }

    // 4. DIRECT INTENT ROUTING TO SUPERPOWER SERVICES
    String? liveContextData;
    final String cleanCmd = command.toLowerCase().trim();

    if (cleanCmd.contains("weather") || cleanCmd.contains("temperature") || cleanCmd.contains("forecast") || cleanCmd.contains("मौसम")) {
      String targetLocation = "Mumbai";
      if (cleanCmd.contains(" in ")) {
        final List<String> parts = cleanCmd.split(" in ");
        if (parts.length > 1) {
          targetLocation = parts[1].replaceAll(RegExp(r'[?.!]'), '').trim();
        }
      }
      _addSystemLog("Direct Routing: Querying Weather API for '$targetLocation'...");
      liveContextData = await SuperpowerService.fetchLiveWeather(targetLocation);
    } 
    else if (cleanCmd.contains("news") || cleanCmd.contains("headlines") || cleanCmd.contains("khabar")) {
      _addSystemLog("Direct Routing: Scraping latest news bulletins...");
      liveContextData = await SuperpowerService.fetchLatestNews();
    } 
    else if (cleanCmd.contains("search") || cleanCmd.contains("lookup") || cleanCmd.contains("who is") || cleanCmd.contains("what is") || cleanCmd.contains("about")) {
      String searchQuery = command;
      if (cleanCmd.startsWith("search ")) {
        searchQuery = command.substring(7).trim();
      } else if (cleanCmd.startsWith("google search ")) {
        searchQuery = command.substring(14).trim();
      }
      _addSystemLog("Direct Routing: Initiating Google Search scrape for '$searchQuery'...");
      liveContextData = await SuperpowerService.performWebSearch(searchQuery);
    }

    // 5. Query OpenAI cognitive service
    final String aiResponse = await OpenAIService.getAIResponse(
      command, 
      apiHistory, 
      injectedData: liveContextData,
    );

    // 6. Detect and Parse automation tags
    final RegExp appRegex = RegExp(r'\[ACTION:\s*OPEN_APP,\s*TARGET:\s*([a-zA-Z0-9_-]+)\]');
    final RegExp flashlightRegex = RegExp(r'\[ACTION:\s*TOGGLE_FLASHLIGHT,\s*STATUS:\s*(ON|OFF)\]');
    final RegExp volumeRegex = RegExp(r'\[ACTION:\s*SET_VOLUME,\s*VALUE:\s*(\d+)\]');
    final RegExp brightnessRegex = RegExp(r'\[ACTION:\s*SET_BRIGHTNESS,\s*VALUE:\s*(\d+)\]');
    final RegExp batteryRegex = RegExp(r'\[ACTION:\s*CHECK_BATTERY\]');
    final RegExp wifiRegex = RegExp(r'\[ACTION:\s*TOGGLE_WIFI,\s*STATUS:\s*(ON|OFF)\]');

    String cleanResponse = aiResponse;
    String? targetApp;
    String? flashlightStatus;
    int? volumeValue;
    int? brightnessValue;
    bool isBatteryCheck = false;
    String? wifiStatus;

    // Parse App
    final Match? appMatch = appRegex.firstMatch(aiResponse);
    if (appMatch != null) {
      targetApp = appMatch.group(1);
      cleanResponse = cleanResponse.replaceAll(appRegex, '');
    }

    // Parse Flashlight
    final Match? torchMatch = flashlightRegex.firstMatch(aiResponse);
    if (torchMatch != null) {
      flashlightStatus = torchMatch.group(1);
      cleanResponse = cleanResponse.replaceAll(flashlightRegex, '');
    }

    // Parse Volume
    final Match? volumeMatch = volumeRegex.firstMatch(aiResponse);
    if (volumeMatch != null) {
      volumeValue = int.tryParse(volumeMatch.group(1) ?? "");
      cleanResponse = cleanResponse.replaceAll(volumeRegex, '');
    }

    // Parse Brightness
    final Match? brightnessMatch = brightnessRegex.firstMatch(aiResponse);
    if (brightnessMatch != null) {
      brightnessValue = int.tryParse(brightnessMatch.group(1) ?? "");
      cleanResponse = cleanResponse.replaceAll(brightnessRegex, '');
    }

    // Parse Battery check
    if (batteryRegex.hasMatch(aiResponse)) {
      isBatteryCheck = true;
      cleanResponse = cleanResponse.replaceAll(batteryRegex, '');
    }

    // Parse WiFi
    final Match? wifiMatch = wifiRegex.firstMatch(aiResponse);
    if (wifiMatch != null) {
      wifiStatus = wifiMatch.group(1);
      cleanResponse = cleanResponse.replaceAll(wifiRegex, '');
    }

    cleanResponse = cleanResponse.trim();

    // 7. Register AI response bubble (Clean text)
    final aiMsg = Message(
      id: DateTime.now().toString(),
      text: cleanResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(aiMsg);
    notifyListeners();

    // 8. Execute mapped automation commands
    if (targetApp != null) {
      await _executeOpenAppAction(targetApp);
    }
    if (flashlightStatus != null) {
      await _executeFlashlight(flashlightStatus == "ON");
    }
    if (volumeValue != null) {
      await _executeSetVolume(volumeValue);
    }
    if (brightnessValue != null) {
      await _executeSetBrightness(brightnessValue);
    }
    if (wifiStatus != null) {
      await _executeToggleWifi(wifiStatus == "ON");
    }

    // 9. Vocalize response
    if (isBatteryCheck) {
      // Announce battery check preliminary sentence first, then call native battery reader
      await speak(cleanResponse);
      await _executeCheckBattery();
    } else {
      await speak(cleanResponse);
    }
  }

  // --- AUTOMATION ACTIONS LAUNCHERS ---

  // Safety checks for System Settings Permission
  Future<bool> _checkSystemWritePermissions() async {
    // Queries System Alert Window permission on Android (analogous to Write Settings check in Flutter packages)
    var status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      status = await Permission.systemAlertWindow.request();
    }
    return status.isGranted;
  }
  
  // A. App launching action
  Future<void> _executeOpenAppAction(String target) async {
    final String appTarget = target.toLowerCase().trim();
    Uri? uri;

    switch (appTarget) {
      case 'whatsapp':
        uri = Uri.parse("whatsapp://");
        break;
      case 'youtube':
        uri = Uri.parse("https://youtube.com");
        break;
      case 'google':
      case 'chrome':
        uri = Uri.parse("https://google.com");
        break;
      case 'gmail':
        uri = Uri.parse("mailto:");
        break;
      case 'calculator':
        uri = Uri.parse("content://com.android.calculator2");
        break;
    }

    if (uri != null) {
      changeState(AssistantState.executing);
      _addSystemLog("Automation: Launching '$appTarget' command...");
      await Future.delayed(const Duration(milliseconds: 1200));

      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (appTarget == 'whatsapp') {
            await launchUrl(Uri.parse("https://web.whatsapp.com"), mode: LaunchMode.externalApplication);
          } else if (appTarget == 'calculator') {
            _addSystemLog("Warning: Could not open local Calculator directly.");
          } else {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        _addSystemLog("Launch failed. Device app '$appTarget' is missing.");
      }
    }
  }

  // B. Flashlight control action
  Future<void> _executeFlashlight(bool turnOn) async {
    changeState(AssistantState.executing);
    _addSystemLog("Automation: Toggling flashlight ${turnOn ? 'ON' : 'OFF'}...");
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      if (turnOn) {
        try {
          await TorchLight.enableTorch();
        } catch (_) {
          await TorchLight.turnOn();
        }
      } else {
        try {
          await TorchLight.disableTorch();
        } catch (_) {
          await TorchLight.turnOff();
        }
      }
    } catch (e) {
      _addSystemLog("Failed to toggle flashlight. Device camera permissions are missing.");
    }
  }

  // C. Volume control action
  Future<void> _executeSetVolume(int value) async {
    changeState(AssistantState.executing);
    _addSystemLog("Automation: Modulating system volume to $value%...");
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final double volumeLevel = (value / 100).clamp(0.0, 1.0);
      await FlutterVolumeController.setVolume(volumeLevel);
    } catch (e) {
      _addSystemLog("Volume adjust failed. System audio controller is restricted.");
    }
  }

  // D. Screen Brightness control action
  Future<void> _executeSetBrightness(int percent) async {
    final bool permissionsGranted = await _checkSystemWritePermissions();
    if (!permissionsGranted) {
      _addSystemLog("Security Alert: System settings write permissions denied.");
      speak("I need permission to alter system settings, Boss. Please grant it on your screen.");
      return;
    }

    changeState(AssistantState.executing);
    _addSystemLog("Automation: Adjusting display brightness to $percent%...");
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final double brightnessVal = (percent / 100.0).clamp(0.0, 1.0);
      await ScreenBrightness().setScreenBrightness(brightnessVal);
    } catch (e) {
      debugPrint("Brightness adjustment failed: $e");
      _addSystemLog("Failed to override screen brightness hardware.");
    }
  }

  // E. Battery monitoring action
  Future<void> _executeCheckBattery() async {
    changeState(AssistantState.executing);
    _addSystemLog("Automation: Querying power cells diagnostics...");
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final int batteryLevel = await _battery.batteryLevel;
      final BatteryState batteryState = await _battery.batteryState;
      final String stateStr = batteryState == BatteryState.charging ? "charging" : "discharging";
      
      final String batteryReport = "Boss, battery power levels are currently at $batteryLevel percent and the device is $stateStr.";

      final aiMsg = Message(
        id: DateTime.now().toString(),
        text: batteryReport,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMsg);
      notifyListeners();

      await speak(batteryReport);
    } catch (e) {
      debugPrint("Battery diagnostics failed: $e");
      _addSystemLog("Failed to fetch battery metrics.");
    }
  }

  // F. WiFi settings toggle action
  Future<void> _executeToggleWifi(bool turnOn) async {
    changeState(AssistantState.executing);
    _addSystemLog("Automation: Directing user to WiFi system controls...");
    await Future.delayed(const Duration(milliseconds: 1200));

    try {
      final Uri wifiSettingsUri = Uri.parse("package:android.settings.WIFI_SETTINGS");
      if (await canLaunchUrl(wifiSettingsUri)) {
        await launchUrl(wifiSettingsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback targeting standard android settings scheme
        await launchUrl(Uri.parse("chrome://settings"), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _addSystemLog("Failed to redirect to WiFi settings panel.");
    }
  }

  void _addSystemLog(String alert) {
    _messages.add(
      Message(
        id: DateTime.now().toString(),
        text: "[SYSTEM]: $alert",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clearChat() {
    _flutterTts.stop();
    _speechToText.stop();
    _vocalTimeoutTimer?.cancel();
    _messages.clear();
    _messages.add(
      Message(
        id: 'welcome_reset',
        text: "Database flushed. Ready for your command, $_userName.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    changeState(AssistantState.idle);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    _vocalTimeoutTimer?.cancel();
    super.dispose();
  }
}

// Extension fallback for older TTS dependencies
extension TtsExtension on FlutterTts {
  Future<dynamic> setThemeValue(double rate) async {
    try {
      return await setSpeechRate(rate);
    } catch (_) {}
  }
}
