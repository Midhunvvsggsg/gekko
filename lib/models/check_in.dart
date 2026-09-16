enum CheckInStatus {
  safe,
  uncertain,
  concerning,
}

class CheckInClassification {
  final CheckInStatus status;
  final String rationale;
  final bool duressDetected;

  const CheckInClassification({
    required this.status,
    required this.rationale,
    required this.duressDetected,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'rationale': rationale,
      'duressDetected': duressDetected,
    };
  }

  factory CheckInClassification.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'safe').toLowerCase();
    CheckInStatus parsedStatus;
    if (statusStr.contains('concerning') || statusStr.contains('danger') || statusStr.contains('escalat')) {
      parsedStatus = CheckInStatus.concerning;
    } else if (statusStr.contains('uncertain') || statusStr.contains('warning') || statusStr.contains('caution')) {
      parsedStatus = CheckInStatus.uncertain;
    } else {
      parsedStatus = CheckInStatus.safe;
    }

    return CheckInClassification(
      status: parsedStatus,
      rationale: json['rationale'] as String? ?? 'Check-in processed successfully.',
      duressDetected: json['duressDetected'] as bool? ?? false,
    );
  }
}

class CheckIn {
  final String id;
  final DateTime timestamp;
  final String promptText;
  final String? userResponse;
  final CheckInClassification? classification;
  final bool isVoice;

  CheckIn({
    required this.id,
    required this.timestamp,
    required this.promptText,
    this.userResponse,
    this.classification,
    this.isVoice = false,
  });

  CheckIn copyWith({
    String? userResponse,
    CheckInClassification? classification,
    bool? isVoice,
  }) {
    return CheckIn(
      id: id,
      timestamp: timestamp,
      promptText: promptText,
      userResponse: userResponse ?? this.userResponse,
      classification: classification ?? this.classification,
      isVoice: isVoice ?? this.isVoice,
    );
  }
}
