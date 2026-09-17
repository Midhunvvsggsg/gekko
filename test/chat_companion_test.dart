import 'package:flutter_test/flutter_test.dart';
import 'package:gekko/models/chat_message.dart';
import 'package:gekko/models/check_in.dart';
import 'package:gekko/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gemini AI Chat Companion Tests', () {
    test('ChatMessage serializes and deserializes correctly', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg_01',
        sender: 'ai',
        text: 'I am your Gekko AI Safety Companion.',
        timestamp: now,
        safetyStatus: CheckInStatus.safe,
        rationale: 'Normal test interaction.',
        rawJson: '{"status":"safe"}',
      );

      final jsonMap = msg.toJson();
      final deserialized = ChatMessage.fromJson(jsonMap);

      expect(deserialized.id, equals('msg_01'));
      expect(deserialized.sender, equals('ai'));
      expect(deserialized.safetyStatus, equals(CheckInStatus.safe));
      expect(deserialized.text, contains('Gekko AI'));
    });

    test('AIService fallback chat engine classifies concerning safety messages', () async {
      final aiService = AIService(); // No API key -> fallback engine

      final response = await aiService.sendChatCompanionMessage(
        userMessage: 'Help me, someone is following me closely and I feel scared',
        history: [],
      );

      expect(response.safetyStatus, equals(CheckInStatus.concerning));
      expect(response.reply, contains('Safety Alert'));
      expect(response.rationale, contains('threat'));
    });

    test('AIService fallback chat engine classifies safe messages', () async {
      final aiService = AIService();

      final response = await aiService.sendChatCompanionMessage(
        userMessage: 'Is this route safe to walk?',
        history: [],
      );

      expect(response.safetyStatus, equals(CheckInStatus.safe));
      expect(response.reply, contains('right here with you'));
    });
  });
}
