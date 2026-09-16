import 'package:flutter/foundation.dart';

class SpeechServiceImpl {
  bool get isListening => false;
  String get lastTranscribedText => '';

  void startListening({
    required Function(String text) onResult,
    required VoidCallback onError,
  }) {
    onResult('Simulated voice input (VM/Desktop mode)...');
  }

  void stopListening() {}

  static void speak(String text) {
    debugPrint('TTS Speak (Stub): $text');
  }

  static void stopSpeaking() {}
}
