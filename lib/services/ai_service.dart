import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/journey_mode_config.dart';
import '../models/journey.dart';
import '../models/check_in.dart';

class AIService {
  final String? apiKey;

  AIService({this.apiKey});

  bool get hasApiKey => apiKey != null && apiKey!.trim().isNotEmpty;

  /// Generates a natural companion small-talk filler line or embedded check-in question using Gemini 2.0 Flash REST API.
  Future<String> generateCompanionLine({
    required bool isCheckInQuestion,
    JourneyModeConfig? mode,
    String? destinationName,
  }) async {
    final modeContext = mode != null ? ' during a ${mode.label} journey' : '';
    final destContext = destinationName != null ? " heading towards $destinationName" : '';

    if (isCheckInQuestion) {
      if (!hasApiKey) return "Hey, just checking in — are you almost home and everything good?";
      try {
        final text = await _callGeminiText(
          "You are acting as a reassuring phone contact ('Mom' or a close friend) talking to someone$modeContext$destContext. "
          "Generate a brief, warm, natural line asking if they are getting home safely. Max 1 short sentence.",
          "Generate companion check-in question.",
        );
        if (text != null && text.trim().isNotEmpty) return text.trim();
      } catch (_) {}
      return "Hey, just checking in — are you almost home and everything good?";
    } else {
      if (!hasApiKey) return "So yeah, work was pretty busy today... how was your afternoon?";
      try {
        final text = await _callGeminiText(
          "You are acting as a reassuring phone contact ('Mom' or a close friend) on a phone call. "
          "Generate a natural, casual filler conversation line (e.g. talking about dinner, weather, weekend plans). Max 1 short sentence.",
          "Generate casual call line.",
        );
        if (text != null && text.trim().isNotEmpty) return text.trim();
      } catch (_) {}
      return "So yeah, work was pretty busy today... how was your afternoon?";
    }
  }

  /// Generates a natural, mode-aware check-in prompt given the journey state.
  Future<String> generateCheckInPrompt(
    JourneyModeConfig mode,
    Journey journey,
  ) async {
    final elapsedMinutes = DateTime.now().difference(journey.startTime).inMinutes;

    if (!hasApiKey) {
      return _fallbackCheckInPrompt(mode, journey.destinationName, elapsedMinutes);
    }

    try {
      final systemInstruction =
          "You are Gekko, an intelligent personal safety companion. "
          "Generate a brief, warm, natural safety check-in prompt for a user currently on a ${mode.label} journey "
          "to '${journey.destinationName}'. Elapsed time: $elapsedMinutes minutes. "
          "Primary risk monitored: ${mode.primaryRiskSignal}. "
          "Keep it concise (1-2 short sentences max). Do not sound robotic or overly alarmist.";

      final prompt = "Generate check-in message.";
      final responseText = await _callGeminiText(systemInstruction, prompt);
      if (responseText != null && responseText.trim().isNotEmpty) {
        return responseText.trim();
      }
    } catch (_) {
      // Fallback on error
    }

    return _fallbackCheckInPrompt(mode, journey.destinationName, elapsedMinutes);
  }

  /// Classifies a user check-in response into safe, uncertain, or concerning.
  /// Also checks for silent duress phrase matching.
  Future<CheckInClassification> classifyCheckInResponse(
    String userResponse,
    String duressPhrase,
    JourneyModeConfig mode,
  ) async {
    // 1. Silent Duress Check (Instant priority check)
    final cleanedInput = userResponse.trim().toLowerCase();
    final cleanedDuress = duressPhrase.trim().toLowerCase();

    if (cleanedDuress.isNotEmpty && cleanedInput.contains(cleanedDuress)) {
      final raw = jsonEncode({
        "status": "safe",
        "rationale": "Response time normal, no deviation, tone neutral.",
        "duressDetected": true,
        "internalTrigger": "Silent duress keyword match detected"
      });
      return CheckInClassification(
        status: CheckInStatus.safe,
        rationale: "Response time normal, no deviation, tone neutral.",
        duressDetected: true,
        rawJson: raw,
      );
    }

    // 2. Call Gemini API if Key available
    if (hasApiKey) {
      try {
        final systemInstruction =
          "You are a personal safety AI engine. Classify the user's safety check-in response "
          "during a ${mode.label} journey. "
          "Return ONLY a valid JSON object matching this schema EXACTLY, with no markdown code blocks:\n"
          "{\n"
          '  "status": "safe" | "uncertain" | "concerning",\n'
          '  "rationale": "One-line clear rationale explanation",\n'
          '  "duressDetected": false\n'
          "}\n"
          "Rules:\n"
          "- 'safe': Normal response, user confirms being okay.\n"
          "- 'uncertain': User feels uncomfortable, followed, uneasy, or unsure of location.\n"
          "- 'concerning': Explicit help request, distress, aggression, coercion, or danger.";

        final body = {
          "contents": [
            {
              "parts": [
                {"text": "User Response: \"$userResponse\""}
              ]
            }
          ],
          "systemInstruction": {
            "parts": [
              {"text": systemInstruction}
            ]
          },
          "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.2
          }
        };

        final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey!.trim()}",
        );

        final res = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null) {
            final cleanJsonStr = _sanitizeJsonText(text);
            final jsonMap = jsonDecode(cleanJsonStr);
            return CheckInClassification.fromJson(jsonMap, rawJson: cleanJsonStr);
          }
        }
      } catch (_) {
        // Fallback on API timeout/error to UNCERTAIN
        final raw = jsonEncode({
          "status": "uncertain",
          "rationale": "Uncertain status due to incomplete telemetry payload.",
          "duressDetected": false,
          "error": "Gemini API timeout or network fallback"
        });
        return CheckInClassification(
          status: CheckInStatus.uncertain,
          rationale: "Uncertain status due to incomplete telemetry payload.",
          duressDetected: false,
          rawJson: raw,
        );
      }
    }

    // 3. Smart Local Fallback Classifier
    return _fallbackClassify(userResponse, mode);
  }

  /// Generates AI summary upon safe arrival at destination.
  Future<String> generateArrivalSummary(Journey journey) async {
    final elapsedMinutes = DateTime.now().difference(journey.startTime).inMinutes.clamp(1, 999);
    final checkInCount = journey.checkIns.length;
    final modeName = journey.mode.label;
    final dest = journey.destinationName;

    if (!hasApiKey) {
      return "$modeName journey to $dest completed in $elapsedMinutes minutes with $checkInCount check-ins, all normal.";
    }

    try {
      final systemInstruction =
          "You are Gekko's Safety Summary Engine. Generate a one-line concise closing summary "
          "for a user who safely completed a $modeName journey to '$dest'. "
          "Duration: $elapsedMinutes minutes, check-ins completed: $checkInCount. "
          "Example: '$modeName journey to $dest completed in $elapsedMinutes minutes with $checkInCount check-ins, all normal.'";

      final summaryText = await _callGeminiText(systemInstruction, "Generate safe arrival summary.");
      if (summaryText != null && summaryText.trim().isNotEmpty) {
        return summaryText.trim();
      }
    } catch (_) {}

    return "$modeName journey to $dest completed in $elapsedMinutes minutes with $checkInCount check-ins, all normal.";
  }

  /// Generates a structured incident summary for emergency contact escalation.
  Future<String> generateIncidentSummary(
    Journey journey,
    CheckIn? triggerCheckIn,
  ) async {
    final mode = journey.mode;
    final timeStr = "${journey.startTime.hour.toString().padLeft(2, '0')}:${journey.startTime.minute.toString().padLeft(2, '0')}";
    final lastKnownLoc = "${journey.currentPosition.latitude.toStringAsFixed(4)}, ${journey.currentPosition.longitude.toStringAsFixed(4)}";

    if (!hasApiKey) {
      return _fallbackIncidentSummary(journey, triggerCheckIn, timeStr, lastKnownLoc);
    }

    try {
      final triggerReason = triggerCheckIn?.classification?.rationale ??
          (journey.isDeviated ? "Route deviation detected" : "Missed check-in countdown timer");

      final systemInstruction =
          "You are Gekko's Emergency Incident Generation Engine. "
          "Create a clear, urgent, structured incident summary to be sent to emergency contacts. "
          "Format with headings: [INCIDENT REPORT], [JOURNEY DETAILS], [TRIGGER CAUSE], [RECOMMENDED ACTION]. "
          "Keep it factual, high-clarity, and actionable.";

      final prompt =
          "Mode: ${mode.label}\n"
          "Destination: ${journey.destinationName}\n"
          "Start Time: $timeStr\n"
          "Last Known Coordinates: $lastKnownLoc\n"
          "Trigger Reason: $triggerReason\n"
          "User Last Response: ${triggerCheckIn?.userResponse ?? 'None'}";

      final summaryText = await _callGeminiText(systemInstruction, prompt);
      if (summaryText != null && summaryText.trim().isNotEmpty) {
        return summaryText.trim();
      }
    } catch (_) {
      // Fallback
    }

    return _fallbackIncidentSummary(journey, triggerCheckIn, timeStr, lastKnownLoc);
  }

  /// Generates pre-journey safety risk briefing.
  Future<String> generateRiskBriefing(
    String location,
    String timeOfDay,
    JourneyModeConfig mode,
  ) async {
    if (!hasApiKey) {
      return _fallbackRiskBriefing(location, timeOfDay, mode);
    }

    try {
      final systemInstruction =
          "You are Gekko's Safety Intelligence Advisor. "
          "Generate a brief 3-bullet safety risk briefing for a user taking a ${mode.label} journey "
          "around $location at $timeOfDay. "
          "Focus on practical vigilance, route awareness, and mode-specific precautions. Keep under 120 words.";

      final prompt = "Generate risk briefing for $location at $timeOfDay during ${mode.label}.";
      final resText = await _callGeminiText(systemInstruction, prompt);
      if (resText != null && resText.trim().isNotEmpty) {
        return resText.trim();
      }
    } catch (_) {
      // Fallback
    }

    return _fallbackRiskBriefing(location, timeOfDay, mode);
  }

  // --- Helper REST Call ---
  Future<String?> _callGeminiText(String systemInstruction, String prompt) async {
    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "systemInstruction": {
        "parts": [
          {"text": systemInstruction}
        ]
      },
      "generationConfig": {
        "temperature": 0.4,
        "maxOutputTokens": 300,
      }
    };

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey!.trim()}",
    );

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    }
    return null;
  }

  String _sanitizeJsonText(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }

  // --- Fallback Generators ---
  String _fallbackCheckInPrompt(JourneyModeConfig mode, String dest, int elapsedMins) {
    switch (mode.id) {
      case 'walking':
        return "Hey there, checking in! You've been walking towards $dest for $elapsedMins mins. Everything going smoothly?";
      case 'train':
        return "Gekko Safety Check: Are you still safely aboard your train towards $dest?";
      case 'bus':
        return "Hey! Checking in on your bus ride to $dest. How is the journey progressing?";
      case 'taxi':
        return "Rideshare Safety Check: How is your ride to $dest going? Does the route look correct?";
      default:
        return "Gekko Check-In: Checking on your journey to $dest. Please confirm you are safe.";
    }
  }

  CheckInClassification _fallbackClassify(String input, JourneyModeConfig mode) {
    final lower = input.toLowerCase();
    CheckInStatus status = CheckInStatus.safe;
    String rationale = "User confirmed normal progress and safe status.";

    if (lower.contains('help') ||
        lower.contains('follow') ||
        lower.contains('following') ||
        lower.contains('chasing') ||
        lower.contains('scared') ||
        lower.contains('danger') ||
        lower.contains('wrong route') ||
        lower.contains('stop car') ||
        lower.contains('emergency') ||
        lower.contains('threat') ||
        lower.contains('attack')) {
      status = CheckInStatus.concerning;
      rationale = "Distress keywords or explicit safety threats detected in response.";
    } else if (lower.contains('uncomfortable') ||
        lower.contains('behind') ||
        lower.contains('nervous') ||
        lower.contains('unsure') ||
        lower.contains('weird') ||
        lower.contains('delay') ||
        lower.contains('dark') ||
        lower.contains('uneasy') ||
        lower.contains('suspicious') ||
        lower.contains('sketchy') ||
        lower.contains('creep') ||
        lower.contains('scary') ||
        lower.contains('watching') ||
        lower.contains('stranger')) {
      status = CheckInStatus.uncertain;
      rationale = "Potential discomfort, trailing entity, or heightened caution indicated.";
    }

    final raw = jsonEncode({
      "status": status.name,
      "rationale": rationale,
      "duressDetected": false,
      "fallbackEngine": "Gekko Local Safety Engine"
    });

    return CheckInClassification(
      status: status,
      rationale: rationale,
      duressDetected: false,
      rawJson: raw,
    );
  }

  String _fallbackIncidentSummary(Journey journey, CheckIn? trigger, String timeStr, String coords) {
    final triggerDesc = trigger?.classification?.rationale ??
        (journey.isDeviated ? "Off-route deviation detected" : "Unresponsive check-in timer expiration");

    return "🚨 EMERGENCY INCIDENT REPORT 🚨\n\n"
        "• Mode: ${journey.mode.label} Journey\n"
        "• Destination: ${journey.destinationName}\n"
        "• Started: $timeStr\n"
        "• Trigger Cause: $triggerDesc\n"
        "• Last Known Coordinates: $coords\n"
        "• User Last Input: \"${trigger?.userResponse ?? 'No response received'}\"\n\n"
        "ACTION TAKEN: Automated emergency escalation dispatched to registered contacts.";
  }

  String _fallbackRiskBriefing(String location, String timeOfDay, JourneyModeConfig mode) {
    return "🛡️ Gekko Safety Risk Briefing ($location • $timeOfDay)\n"
        "• Mode (${mode.label}): ${mode.primaryRiskSignal} is actively monitored.\n"
        "• Vigilance: Keep mobile phone accessible, share live journey link, and avoid unlit paths.\n"
        "• Escalation: Emergency SOS triggers will immediately dispatch your location to emergency contacts.";
  }

  /// Returns mode-specific safety advice for UNCERTAIN situations.
  static String getModeSafetyGuidance(JourneyModeConfig mode) {
    switch (mode.id) {
      case 'walking':
        return "Head immediately towards the nearest open business, hotel lobby, or well-lit main street. Avoid unlit shortcuts and keep your phone in hand.";
      case 'bus':
        return "Move immediately to a seat closer to the bus driver. Stay seated in clear line of sight of other passengers.";
      case 'taxi':
        return "Verify driver name & license plate match your booking. Ask driver to stay on the GPS route and share your live tracking link.";
      case 'train':
        return "Move towards the conductor's car or a busier train carriage near the emergency intercom button.";
      default:
        return "Head towards a well-lit public area with people nearby. Keep your phone in hand and stay vigilant.";
    }
  }

  /// Returns mode-specific local police precinct contact details.
  static Map<String, String> getModePolicePrecinct(JourneyModeConfig mode) {
    switch (mode.id) {
      case 'walking':
        return {
          'name': 'SFPD Central Police Precinct',
          'phone': '+1 415-553-0123',
          'type': 'Local Police Precinct',
        };
      case 'bus':
        return {
          'name': 'Muni Transit Police Dispatch',
          'phone': '+1 415-554-9800',
          'type': 'Public Transit Police',
        };
      case 'taxi':
        return {
          'name': 'Traffic & Highway Patrol Dispatch',
          'phone': '+1 415-553-0123',
          'type': 'Rideshare & Traffic Division',
        };
      case 'train':
        return {
          'name': 'BART & Rail Transit Police',
          'phone': '+1 510-464-7000',
          'type': 'Metro Rail Transit Police',
        };
      default:
        return {
          'name': 'Emergency Dispatch Center',
          'phone': '911',
          'type': 'Emergency Services',
        };
    }
  }
}
