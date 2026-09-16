import 'package:flutter/foundation.dart';
import 'speech_service_stub.dart' if (dart.library.html) 'speech_service_web.dart';

class SpeechService {
  final SpeechServiceImpl _impl = SpeechServiceImpl();

  bool get isListening => _impl.isListening;
  String get lastTranscribedText => _impl.lastTranscribedText;

  void startListening({
    required Function(String text) onResult,
    required VoidCallback onError,
  }) {
    _impl.startListening(onResult: onResult, onError: onError);
  }

  void stopListening() {
    _impl.stopListening();
  }

  static void speak(String text) {
    SpeechServiceImpl.speak(text);
  }

  static void stopSpeaking() {
    SpeechServiceImpl.stopSpeaking();
  }
}
