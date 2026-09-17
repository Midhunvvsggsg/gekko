import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/journey.dart';
import '../models/journey_mode_config.dart';
import '../models/check_in.dart';
import '../services/ai_service.dart';
import '../services/location_service.dart';
import '../services/journey_sync_service.dart';
import '../services/speed_classifier_service.dart';
import '../services/mesh_relay_service.dart';
import 'ai_provider.dart';
import 'settings_provider.dart';
import 'stealth_provider.dart';

class JourneyStateNotifier extends StateNotifier<Journey?> {
  final AIService _aiService;
  final JourneySyncService _syncService;
  final MeshRelayService _meshService;
  final String _duressPhrase;
  final bool _isDemoMode;
  final bool _isStealthModeActive;

  final SpeedClassifierService _speedClassifier = SpeedClassifierService();

  Timer? _countdownTimer;
  Timer? _locationTimer;

  int _secondsToNextCheckIn = 0;
  int get secondsToNextCheckIn => _secondsToNextCheckIn;

  JourneyStateNotifier(
    this._aiService,
    this._syncService,
    this._meshService,
    this._duressPhrase,
    this._isDemoMode,
    this._isStealthModeActive,
  ) : super(null);

  /// Starts a new journey with the specified JourneyModeConfig
  Future<void> startJourney({
    required JourneyModeConfig mode,
    required String destinationName,
    required LatLng destinationLatLng,
    required Duration expectedDuration,
    LatLng? startLatLng,
  }) async {
    _speedClassifier.reset();
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
    await _syncService.publishJourney(newJourney);

    // Generate Risk Briefing asynchronously
    final briefing = await _aiService.generateRiskBriefing(
      destinationName,
      "Evening",
      mode,
    );
    if (state != null) {
      state = state!.copyWith(riskBriefing: briefing);
      await _syncService.publishJourney(state!);
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
        // Trigger Check-In (Passive if in Stealth Mode, Interactive otherwise)
        if (_isStealthModeActive) {
          _performPassiveCheckIn();
        } else {
          _triggerPendingCheckIn();
        }
      }
    });

    // Location update timer (simulates movement along route)
    int routeIdx = 0;
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      if (state == null || state!.status != JourneyStatus.active || state!.isDeviated) return;

      if (state!.routePoints.isNotEmpty) {
        routeIdx = (routeIdx + 1) % state!.routePoints.length;
        final nextPos = state!.routePoints[routeIdx];
        final now = DateTime.now();

        _speedClassifier.addSample(nextPos, now);
        final speedRes = _speedClassifier.evaluateCurrentSpeed();

        // Check for Auto Mode-Switch (Walking -> Bus on sustained vehicle speed)
        if (speedRes.shouldSwitchMode &&
            state!.mode.id != 'train' &&
            state!.mode.id != 'bus' &&
            !state!.userManualOverride) {
          final busMode = JourneyModeConfig.defaultModes.firstWhere(
            (m) => m.id == 'bus',
            orElse: () => state!.mode,
          );

          final autoSwitchEvent = CheckIn(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: now,
            promptText: 'Auto Mode-Switch Engine',
            userResponse: '[Vehicle Speed ${speedRes.currentSpeedKmh.toStringAsFixed(0)} km/h Detected]',
            classification: CheckInClassification(
              status: CheckInStatus.safe,
              rationale: 'Automated transition to Bus monitoring profile based on sustained vehicle speed.',
              duressDetected: false,
            ),
          );

          state = state!.copyWith(
            mode: busMode,
            autoSwitchedNotice: 'Detected vehicle speed (${speedRes.currentSpeedKmh.toStringAsFixed(0)} km/h) — switched to Bus monitoring profile',
            checkIns: [...state!.checkIns, autoSwitchEvent],
            currentPosition: nextPos,
          );
          _resetCheckInCountdown();
        } else {
          state = state!.copyWith(currentPosition: nextPos);
        }

        await _syncService.publishJourney(state!);
      }
    });
  }

  /// Demo Trigger: Simulates sustained vehicle speed (25 km/h) to test auto mode-switching live
  void simulateVehicleSpeed() {
    if (state == null) return;
    final now = DateTime.now();
    final currentPos = state!.currentPosition;

    // Inject fake distant points to simulate vehicle speed
    const Distance dist = Distance();
    final p1 = dist.offset(currentPos, 200, 90);
    final p2 = dist.offset(p1, 200, 90);

    _speedClassifier.addSample(currentPos, now.subtract(const Duration(seconds: 4)));
    _speedClassifier.addSample(p1, now.subtract(const Duration(seconds: 2)));
    _speedClassifier.addSample(p2, now);

    final busMode = JourneyModeConfig.defaultModes.firstWhere(
      (m) => m.id == 'bus',
      orElse: () => state!.mode,
    );

    final autoSwitchEvent = CheckIn(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: now,
      promptText: 'Auto Mode-Switch Engine (Simulated)',
      userResponse: '[Simulated Vehicle Speed 25 km/h]',
      classification: const CheckInClassification(
        status: CheckInStatus.safe,
        rationale: 'Automated transition to Bus monitoring profile based on sustained vehicle speed.',
        duressDetected: false,
      ),
    );

    state = state!.copyWith(
      mode: busMode,
      autoSwitchedNotice: 'Detected vehicle speed (25 km/h) — switched to Bus monitoring profile',
      checkIns: [...state!.checkIns, autoSwitchEvent],
    );
    _resetCheckInCountdown();
    _syncService.publishJourney(state!);
  }

  /// Manually override / reselect mode during an active journey
  void overrideMode(JourneyModeConfig newMode) {
    if (state == null) return;
    state = state!.copyWith(
      mode: newMode,
      userManualOverride: true,
      clearAutoSwitchNotice: true,
    );
    _resetCheckInCountdown();
    _syncService.publishJourney(state!);
  }

  /// Dismiss auto-switch notification banner
  void dismissAutoSwitchNotice() {
    if (state == null) return;
    state = state!.copyWith(clearAutoSwitchNotice: true);
  }

  Future<void> _triggerPendingCheckIn() async {
    if (state == null) return;

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
    await _syncService.publishJourney(state!);
  }

  Future<void> _performPassiveCheckIn() async {
    if (state == null) return;

    if (state!.isDeviated) {
      final updatedCheckIn = CheckIn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        promptText: 'Passive GPS Monitoring (Stealth Mode)',
        userResponse: '[Off-Route Deviation Detected]',
        classification: const CheckInClassification(
          status: CheckInStatus.concerning,
          rationale: 'Passive monitoring detected off-route deviation during Stealth Mode.',
          duressDetected: false,
        ),
      );
      final updatedCheckIns = [...state!.checkIns, updatedCheckIn];

      final summary = await _aiService.generateIncidentSummary(state!, updatedCheckIn);
      state = state!.copyWith(
        status: JourneyStatus.escalated,
        checkIns: updatedCheckIns,
        incidentSummary: summary,
      );
    } else {
      final silentCheckIn = CheckIn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        promptText: 'Passive AI Check-In (Stealth Mode)',
        userResponse: '[Passive Auto-Verified]',
        classification: const CheckInClassification(
          status: CheckInStatus.safe,
          rationale: 'Passive signals normal. Route & pace verified in Stealth Mode.',
          duressDetected: false,
        ),
      );
      final updatedCheckIns = [...state!.checkIns, silentCheckIn];
      state = state!.copyWith(
        status: JourneyStatus.active,
        checkIns: updatedCheckIns,
      );
      _resetCheckInCountdown();
    }
    await _syncService.publishJourney(state!);
  }

  /// User responds to check-in prompt via modal or voice companion
  Future<CheckInClassification> submitCheckInResponse(
    String userResponse, {
    bool isVoice = false,
  }) async {
    if (state == null) {
      return const CheckInClassification(
        status: CheckInStatus.safe,
        rationale: 'No active journey.',
        duressDetected: false,
      );
    }

    // Ensure there is a CheckIn record to attach this response to
    CheckIn currentCheckIn;
    List<CheckIn> existingCheckIns = List.from(state!.checkIns);

    if (existingCheckIns.isEmpty || existingCheckIns.last.userResponse != null) {
      final promptText = await _aiService.generateCheckInPrompt(state!.mode, state!);
      currentCheckIn = CheckIn(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        promptText: promptText,
      );
      existingCheckIns.add(currentCheckIn);
    } else {
      currentCheckIn = existingCheckIns.last;
    }

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
      ...existingCheckIns.sublist(0, existingCheckIns.length - 1),
      updatedCheckIn,
    ];

    if (classification.status == CheckInStatus.concerning || classification.duressDetected) {
      final summary = await _aiService.generateIncidentSummary(state!, updatedCheckIn);
      state = state!.copyWith(
        status: JourneyStatus.escalated,
        checkIns: updatedCheckIns,
        incidentSummary: summary,
      );
    } else {
      state = state!.copyWith(
        status: JourneyStatus.active,
        checkIns: updatedCheckIns,
      );
      _resetCheckInCountdown();
    }

    await _syncService.publishJourney(state!);
    return classification;
  }

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
      if (_isStealthModeActive) {
        _performPassiveCheckIn();
      } else {
        _triggerPendingCheckIn();
      }
    }
    _syncService.publishJourney(state!);
  }

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
    await _syncService.publishJourney(state!);

    // Initialize offline P2P delay-tolerant mesh packet
    await _meshService.createSosPacket(
      journey: state!,
      triggerSource: triggerSource,
    );
  }

  Future<void> completeJourney() async {
    if (state == null) return;
    _stopTimers();
    final arrivalSummary = await _aiService.generateArrivalSummary(state!);
    state = state!.copyWith(
      status: JourneyStatus.completed,
      arrivalSummary: arrivalSummary,
    );
    await _syncService.publishJourney(state!);
  }

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
  final syncService = ref.watch(journeySyncServiceProvider);
  final meshService = ref.watch(meshRelayServiceProvider);
  final duressPhrase = ref.watch(settingsProvider.select((s) => s.duressPhrase));
  final isDemoMode = ref.watch(settingsProvider.select((s) => s.isDemoMode));
  final isStealthModeActive = ref.watch(stealthProvider.select((s) => s.isStealthModeActive));
  return JourneyStateNotifier(aiService, syncService, meshService, duressPhrase, isDemoMode, isStealthModeActive);
});
