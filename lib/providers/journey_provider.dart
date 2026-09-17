import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/journey.dart';
import '../models/journey_mode_config.dart';
import '../models/check_in.dart';
import '../services/ai_service.dart';
import '../services/location_service.dart';
import 'ai_provider.dart';
import 'settings_provider.dart';

class JourneyStateNotifier extends StateNotifier<Journey?> {
  final AIService _aiService;
  final String _duressPhrase;
  final bool _isDemoMode;

  Timer? _countdownTimer;
  Timer? _locationTimer;

  int _secondsToNextCheckIn = 0;
  int get secondsToNextCheckIn => _secondsToNextCheckIn;

  JourneyStateNotifier(this._aiService, this._duressPhrase, this._isDemoMode) : super(null);

  /// Starts a new journey with the specified JourneyModeConfig
  Future<void> startJourney({
    required JourneyModeConfig mode,
    required String destinationName,
    required LatLng destinationLatLng,
    required Duration expectedDuration,
    LatLng? startLatLng,
  }) async {
    final startPos = startLatLng ?? LocationService.defaultStart;
    final routePoints = LocationService.generateMockRoute(startPos, destinationLatLng);

    final newJourney = Journey(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: mode,
      destinationName: destinationName,
      destinationLatLng: destinationLatLng,
      startTime: DateTime.now(),
      expectedDuration: expectedDuration,
      status: JourneyStatus.active,
      routePoints: routePoints,
      currentPosition: startPos,
    );

    state = newJourney;

    // Generate Risk Briefing asynchronously
    final briefing = await _aiService.generateRiskBriefing(
      destinationName,
      "Evening",
      mode,
    );
    if (state != null) {
      state = state!.copyWith(riskBriefing: briefing);
    }

    _resetCheckInCountdown();
    _startTimers();
  }

  void _resetCheckInCountdown() {
    if (state == null) return;
    if (_isDemoMode) {
      _secondsToNextCheckIn = 15;
    } else {
      final modeMins = state!.mode.checkInInterval.inMinutes;
      _secondsToNextCheckIn = (modeMins * 60).clamp(15, 3600);
    }
  }

  void _startTimers() {
    _countdownTimer?.cancel();
    _locationTimer?.cancel();

    // Countdown Timer (runs every second)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state == null || state!.status != JourneyStatus.active) return;

      if (_secondsToNextCheckIn > 0) {
        _secondsToNextCheckIn--;
        // Force state notification tick for timer UI
        state = state!.copyWith();
      } else {
        // Trigger Check-In Pending
        _triggerPendingCheckIn();
      }
    });

    // Location update timer (simulates movement along route)
    int routeIdx = 0;
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (state == null || state!.status != JourneyStatus.active || state!.isDeviated) return;

      if (state!.routePoints.isNotEmpty) {
        routeIdx = (routeIdx + 1) % state!.routePoints.length;
        final nextPos = state!.routePoints[routeIdx];
        state = state!.copyWith(currentPosition: nextPos);
      }
    });
  }

  Future<void> _triggerPendingCheckIn() async {
    if (state == null) return;

    // Generate context-aware prompt from Gemini
    final promptText = await _aiService.generateCheckInPrompt(state!.mode, state!);

    final pendingCheckIn = CheckIn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      promptText: promptText,
    );

    final updatedCheckIns = [...state!.checkIns, pendingCheckIn];

    state = state!.copyWith(
      status: JourneyStatus.checkInPending,
      checkIns: updatedCheckIns,
    );
  }

  /// User responds to check-in prompt via modal
  Future<CheckInClassification> submitCheckInResponse(
    String userResponse, {
    bool isVoice = false,
  }) async {
    if (state == null || state!.checkIns.isEmpty) {
      return const CheckInClassification(
        status: CheckInStatus.safe,
        rationale: 'Journey in progress.',
        duressDetected: false,
      );
    }

    final currentCheckIn = state!.checkIns.last;
    final classification = await _aiService.classifyCheckInResponse(
      userResponse,
      _duressPhrase,
      state!.mode,
    );

    final updatedCheckIn = currentCheckIn.copyWith(
      userResponse: userResponse,
      classification: classification,
      isVoice: isVoice,
    );

    final updatedCheckIns = [
      ...state!.checkIns.sublist(0, state!.checkIns.length - 1),
      updatedCheckIn,
    ];

    if (classification.status == CheckInStatus.concerning || classification.duressDetected) {
      // Escalation / SOS state triggered!
      final summary = await _aiService.generateIncidentSummary(state!, updatedCheckIn);
      state = state!.copyWith(
        status: JourneyStatus.escalated,
        checkIns: updatedCheckIns,
        incidentSummary: summary,
      );
    } else {
      // Safe or Uncertain -> Continue Journey
      state = state!.copyWith(
        status: JourneyStatus.active,
        checkIns: updatedCheckIns,
      );
      _resetCheckInCountdown();
    }

    return classification;
  }

  /// Manually toggle route deviation to test safety engine
  void toggleOffRouteDeviation() {
    if (state == null) return;

    final newDeviated = !state!.isDeviated;
    LatLng newPos = state!.currentPosition;

    if (newDeviated) {
      newPos = LocationService.generateDeviatedPoint(state!.currentPosition);
    }

    state = state!.copyWith(
      isDeviated: newDeviated,
      currentPosition: newPos,
    );

    if (newDeviated && state!.mode.trustLiveGps) {
      // Instantly trigger check-in modal on deviation if mode trusts live GPS
      _triggerPendingCheckIn();
    }
  }

  /// Trigger manual SOS or automated timer timeout escalation
  Future<void> triggerSOS({String triggerSource = 'Manual SOS Button'}) async {
    if (state == null) return;

    final summary = await _aiService.generateIncidentSummary(
      state!,
      CheckIn(
        id: 'sos_manual',
        timestamp: DateTime.now(),
        promptText: triggerSource,
        userResponse: 'SOS Emergency Triggered',
        classification: CheckInClassification(
          status: CheckInStatus.concerning,
          rationale: triggerSource,
          duressDetected: false,
        ),
      ),
    );

    state = state!.copyWith(
      status: JourneyStatus.escalated,
      incidentSummary: summary,
    );
  }

  /// Complete Journey Safely
  Future<void> completeJourney() async {
    if (state == null) return;
    _stopTimers();
    final arrivalSummary = await _aiService.generateArrivalSummary(state!);
    state = state!.copyWith(
      status: JourneyStatus.completed,
      arrivalSummary: arrivalSummary,
    );
  }

  /// Cancel & Reset
  void cancelJourney() {
    _stopTimers();
    state = null;
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _locationTimer?.cancel();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}

final journeyProvider = StateNotifierProvider<JourneyStateNotifier, Journey?>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final duressPhrase = ref.watch(settingsProvider.select((s) => s.duressPhrase));
  final isDemoMode = ref.watch(settingsProvider.select((s) => s.isDemoMode));
  return JourneyStateNotifier(aiService, duressPhrase, isDemoMode);
});
