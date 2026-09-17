import 'package:latlong2/latlong.dart';
import 'journey_mode_config.dart';
import 'check_in.dart';

enum JourneyStatus {
  idle,
  active,
  checkInPending,
  escalated,
  completed,
}

class Journey {
  final String id;
  final JourneyModeConfig mode;
  final String destinationName;
  final LatLng destinationLatLng;
  final DateTime startTime;
  final Duration expectedDuration;
  final JourneyStatus status;
  final List<CheckIn> checkIns;
  final List<LatLng> routePoints;
  final LatLng currentPosition;
  final bool isDeviated;
  final bool userManualOverride;
  final String? autoSwitchedNotice;
  final String? incidentSummary;
  final String? riskBriefing;
  final String? arrivalSummary;

  Journey({
    required this.id,
    required this.mode,
    required this.destinationName,
    required this.destinationLatLng,
    required this.startTime,
    required this.expectedDuration,
    this.status = JourneyStatus.active,
    this.checkIns = const [],
    this.routePoints = const [],
    required this.currentPosition,
    this.isDeviated = false,
    this.userManualOverride = false,
    this.autoSwitchedNotice,
    this.incidentSummary,
    this.riskBriefing,
    this.arrivalSummary,
  });

  Journey copyWith({
    JourneyModeConfig? mode,
    JourneyStatus? status,
    List<CheckIn>? checkIns,
    List<LatLng>? routePoints,
    LatLng? currentPosition,
    bool? isDeviated,
    bool? userManualOverride,
    String? autoSwitchedNotice,
    bool clearAutoSwitchNotice = false,
    String? incidentSummary,
    String? riskBriefing,
    String? arrivalSummary,
  }) {
    return Journey(
      id: id,
      mode: mode ?? this.mode,
      destinationName: destinationName,
      destinationLatLng: destinationLatLng,
      startTime: startTime,
      expectedDuration: expectedDuration,
      status: status ?? this.status,
      checkIns: checkIns ?? this.checkIns,
      routePoints: routePoints ?? this.routePoints,
      currentPosition: currentPosition ?? this.currentPosition,
      isDeviated: isDeviated ?? this.isDeviated,
      userManualOverride: userManualOverride ?? this.userManualOverride,
      autoSwitchedNotice: clearAutoSwitchNotice ? null : (autoSwitchedNotice ?? this.autoSwitchedNotice),
      incidentSummary: incidentSummary ?? this.incidentSummary,
      riskBriefing: riskBriefing ?? this.riskBriefing,
      arrivalSummary: arrivalSummary ?? this.arrivalSummary,
    );
  }
}
