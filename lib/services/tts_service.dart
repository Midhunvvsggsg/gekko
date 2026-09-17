import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  late FlutterTts _flutterTts;
  bool _initialized = false;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _initialized = true;
    } catch (_) {
      // Fallback if TTS unavailable
      _initialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_initialized) await _initTts();
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      if (_initialized) {
        await _flutterTts.stop();
      }
    } catch (_) {}
  }
}
