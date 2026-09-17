import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/journey.dart';
import '../services/ai_service.dart';
import 'ai_provider.dart';
import 'journey_provider.dart';

class ChatCompanionState {
  final List<ChatMessage> messages;
  final bool isSending;

  const ChatCompanionState({
    required this.messages,
    this.isSending = false,
  });

  ChatCompanionState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
  }) {
    return ChatCompanionState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatCompanionNotifier extends StateNotifier<ChatCompanionState> {
  final AIService _aiService;

  ChatCompanionNotifier(this._aiService, Journey? activeJourney)
      : super(ChatCompanionState(
          messages: [
            ChatMessage(
              id: 'init_msg',
              sender: 'ai',
              text: activeJourney != null
                  ? "Hey! I'm your Gekko AI Safety Companion. I'm actively monitoring your ${activeJourney.mode.label} journey to '${activeJourney.destinationName}'. How is your trip going? Feel free to ask for safety advice or tell me if you feel uneasy!"
                  : "Hello! I am your Gekko AI Safety Companion. Ask me route safety questions or start a monitored journey to get real-time trip protection!",
              timestamp: DateTime.now(),
            ),
          ],
        ));

  Future<void> sendMessage(String userText, Journey? activeJourney) async {
    final text = userText.trim();
    if (text.isEmpty || state.isSending) return;

    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    final updated = [...state.messages, userMsg];
    state = state.copyWith(messages: updated, isSending: true);

    final historyMap = state.messages.map((m) {
      return {
        'sender': m.sender,
        'text': m.text,
      };
    }).toList();

    final response = await _aiService.sendChatCompanionMessage(
      userMessage: text,
      history: historyMap,
      mode: activeJourney?.mode,
      destinationName: activeJourney?.destinationName,
    );

    final aiMsg = ChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'ai',
      text: response.reply,
      timestamp: DateTime.now(),
      safetyStatus: response.safetyStatus,
      rationale: response.rationale,
      rawJson: response.rawJson,
    );

    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isSending: false,
    );
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}

final chatCompanionProvider = StateNotifierProvider<ChatCompanionNotifier, ChatCompanionState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final activeJourney = ref.watch(journeyProvider);
  return ChatCompanionNotifier(aiService, activeJourney);
});
