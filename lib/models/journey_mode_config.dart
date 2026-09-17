import 'package:flutter/material.dart';

class JourneyModeConfig {
  final String id;
  final String label;
  final IconData icon;
  final Duration checkInInterval;
  final bool trustLiveGps;
  final bool useScheduledCheckpoints;
  final String primaryRiskSignal;
  final Duration escalationGracePeriod;
  final String modeDescription;

  final double averageSpeedKmH;

  const JourneyModeConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.checkInInterval,
    required this.trustLiveGps,
    required this.useScheduledCheckpoints,
    required this.primaryRiskSignal,
    required this.escalationGracePeriod,
    required this.modeDescription,
    this.averageSpeedKmH = 20.0,
  });

  Duration calculateEstimatedDuration(double distanceKm) {
    if (distanceKm <= 0 || averageSpeedKmH <= 0) {
      return const Duration(minutes: 15);
    }
    final hours = distanceKm / averageSpeedKmH;
    final mins = (hours * 60).round().clamp(3, 1440);
    return Duration(minutes: mins);
  }

  static const List<JourneyModeConfig> defaultModes = [
    JourneyModeConfig(
      id: 'walking',
      label: 'Walking',
      icon: Icons.directions_walk,
      checkInInterval: Duration(minutes: 8),
      trustLiveGps: true,
      useScheduledCheckpoints: false,
      primaryRiskSignal: 'Route deviation or prolonged unexpected stop',
      escalationGracePeriod: Duration(minutes: 3),
      modeDescription: 'Continuous GPS tracking active. AI will prompt check-in every 8 mins or on unexpected stops.',
      averageSpeedKmH: 5.0,
    ),
    JourneyModeConfig(
      id: 'train',
      label: 'Train / Metro',
      icon: Icons.train,
      checkInInterval: Duration(minutes: 20),
      trustLiveGps: false,
      useScheduledCheckpoints: true,
      primaryRiskSignal: 'Missed scheduled arrival window or station pass-through',
      escalationGracePeriod: Duration(minutes: 10),
      modeDescription: 'Station-to-station checkpoint monitoring. Reduced GPS tracking inside underground tunnels.',
      averageSpeedKmH: 45.0,
    ),
    JourneyModeConfig(
      id: 'bus',
      label: 'Bus',
      icon: Icons.directions_bus,
      checkInInterval: Duration(minutes: 15),
      trustLiveGps: true,
      useScheduledCheckpoints: false,
      primaryRiskSignal: 'Missed expected transit stop or unexpected detour',
      escalationGracePeriod: Duration(minutes: 8),
      modeDescription: 'Light GPS monitoring with periodic check-ins every 15 mins based on route progress.',
      averageSpeedKmH: 25.0,
    ),
    JourneyModeConfig(
      id: 'taxi',
      label: 'Taxi / Rideshare',
      icon: Icons.local_taxi,
      checkInInterval: Duration(minutes: 10),
      trustLiveGps: true,
      useScheduledCheckpoints: false,
      primaryRiskSignal: 'Sharp route deviation or unannounced off-path stop',
      escalationGracePeriod: Duration(minutes: 2),
      modeDescription: 'High-security route deviation tracking. Short grace period for fast escalation if needed.',
      averageSpeedKmH: 35.0,
    ),
    JourneyModeConfig(
      id: 'other',
      label: 'Other Journey',
      icon: Icons.explore,
      checkInInterval: Duration(minutes: 15),
      trustLiveGps: false,
      useScheduledCheckpoints: false,
      primaryRiskSignal: 'Overall journey timeout without safety response',
      escalationGracePeriod: Duration(minutes: 5),
      modeDescription: 'General timer monitoring with customizable safety prompts.',
      averageSpeedKmH: 20.0,
    ),
  ];

  static JourneyModeConfig getById(String id) {
    return defaultModes.firstWhere(
      (m) => m.id == id,
      orElse: () => defaultModes.last,
    );
  }
}
