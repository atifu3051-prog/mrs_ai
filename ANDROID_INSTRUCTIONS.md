# Android Permissions Configuration for MRS AI (Voice Phase 2)

To enable speech-to-text (STT) and text-to-speech (TTS) features on Android, you must declare audio capture and internet permissions in your Android configurations.

## 1. Edit `AndroidManifest.xml`
Locate your main Android manifest file at:
`android/app/src/main/AndroidManifest.xml`

### Add Recording Permissions
Insert these permission declarations inside the `<manifest>` tag, above the `<application>` tag:

```xml
    <!-- Permissions for Speech-to-Text and Text-to-Speech -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Permissions for Flashlight/Torch control -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" />
    <uses-feature android:name="android.hardware.camera.flash" />

    <!-- Permissions for system settings overrides (Volume, Brightness, WiFi) -->
    <uses-permission android:name="android.permission.WRITE_SETTINGS" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

### Add Queries Block (Crucial for Android 11+ / API 30+)
Android 11 restricts package visibility by default. Without adding a `<queries>` block, the `speech_to_text` plugin will fail to discover speech services on modern Android phones.

Insert the following block inside the `<manifest>` root tag (parallel to `<uses-permission>`):

```xml
    <!-- Allow access to Android Speech Recognition Service -->
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService" />
        </intent>
    </queries>
```

---

## 2. Check Android Min SDK Version
Locate your app-level build file at:
`android/app/build.gradle`

Ensure your `minSdkVersion` is set to **21** or higher (required by `flutter_tts` and `speech_to_text` plugins):
```groovy
defaultConfig {
    ...
    minSdkVersion 21
    ...
}
```
