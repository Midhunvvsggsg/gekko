import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class SpeechServiceImpl {
  html.SpeechRecognition? _speechRecognition;
  bool _isListening = false;
  String _lastTranscribedText = '';

  bool get isListening => _isListening;
  String get lastTranscribedText => _lastTranscribedText;

  void startListening({
    required Function(String text) onResult,
    required VoidCallback onError,
  }) {
    if (kIsWeb) {
      try {
        if (html.SpeechRecognition.supported) {
          _speechRecognition = html.SpeechRecognition();
          _speechRecognition!.continuous = false;
          _speechRecognition!.interimResults = true;
          _speechRecognition!.lang = 'en-US';

          _speechRecognition!.onResult.listen((html.SpeechRecognitionEvent event) {
            final dynamic results = event.results;
            if (results != null && (results.length as int) > 0) {
              final String transcript = results[0][0].transcript?.toString() ?? '';
              _lastTranscribedText = transcript;
              onResult(transcript);
            }
          });

          _speechRecognition!.onError.listen((event) {
            _isListening = false;
            onError();
          });

          _speechRecognition!.onEnd.listen((event) {
            _isListening = false;
          });

          _speechRecognition!.start();
          _isListening = true;
          return;
        }
      } catch (e) {
        debugPrint('Web Speech Recognition error: $e');
      }
    }

    _isListening = true;
    onResult('Simulated voice input...');
  }

  void stopListening() {
    if (_speechRecognition != null && _isListening) {
      try {
        _speechRecognition!.stop();
      } catch (_) {}
    }
    _isListening = false;
  }

  static void speak(String text) {
    if (kIsWeb && html.window.speechSynthesis != null) {
      try {
        html.window.speechSynthesis!.cancel();
        final utterance = html.SpeechSynthesisUtterance(text);
        utterance.rate = 1.0;
        utterance.pitch = 1.0;
        utterance.lang = 'en-US';
        html.window.speechSynthesis!.speak(utterance);
      } catch (e) {
        debugPrint('Speech Synthesis error: $e');
      }
    }
  }

  static void stopSpeaking() {
    if (kIsWeb && html.window.speechSynthesis != null) {
      try {
        html.window.speechSynthesis!.cancel();
      } catch (_) {}
    }
  }
}
