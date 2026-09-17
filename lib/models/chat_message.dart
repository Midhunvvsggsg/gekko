import 'check_in.dart';

class ChatMessage {
  final String id;
  final String sender; // 'user', 'ai', 'system'
  final String text;
  final DateTime timestamp;
  final CheckInStatus? safetyStatus;
  final String? rationale;
  final String? rawJson;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.safetyStatus,
    this.rationale,
    this.rawJson,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'safetyStatus': safetyStatus?.name,
        'rationale': rationale,
        'rawJson': rawJson,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    CheckInStatus? status;
    if (json['safetyStatus'] != null) {
      status = CheckInStatus.values.firstWhere(
        (s) => s.name == json['safetyStatus'],
        orElse: () => CheckInStatus.safe,
      );
    }

    return ChatMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      safetyStatus: status,
      rationale: json['rationale'] as String?,
      rawJson: json['rawJson'] as String?,
    );
  }
}
