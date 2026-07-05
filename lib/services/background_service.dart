import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

class BackgroundWakeWordService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'mrs_ai_wake_word',
        initialNotificationTitle: 'MRS AI Wake Word',
        initialNotificationContent: 'Listening for "Hey Mrs" background cue...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
    debugPrint("Background wake word service initialized successfully.");
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Mock wake-word processing loop (Runs in secondary background isolate/thread)
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Simulates finding the "Hey Mrs" vocal cue in the mic stream
        // and triggering the main UI to wake up
        debugPrint("[Background Isolate]: Scanning background vocal frames for 'Hey Mrs'...");
        
        // Push an event to the main UI stream
        service.invoke(
          'onWakeWordDetected',
          {
            "timestamp": DateTime.now().toIso8601String(),
            "confidence": 0.94,
          },
        );
      }
    }
  });
}
