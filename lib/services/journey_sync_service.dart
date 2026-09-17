import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/journey.dart';
import '../providers/settings_provider.dart';
import 'storage_service.dart';

class PublicJourneySnapshot {
  final String id;
  final String modeLabel;
  final String destinationName;
  final String status; // 'active', 'completed', 'escalated'
  final DateTime startTime;
  final int expectedDurationMinutes;
  final LatLng lastKnownLocation;
  final List<LatLng> routePoints;
  final String lastCheckInStatus; // 'safe', 'uncertain', 'concerning', 'pending'
  final DateTime lastUpdated;

  PublicJourneySnapshot({
    required this.id,
    required this.modeLabel,
    required this.destinationName,
    required this.status,
    required this.startTime,
    required this.expectedDurationMinutes,
    required this.lastKnownLocation,
    required this.routePoints,
    required this.lastCheckInStatus,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'modeLabel': modeLabel,
        'destinationName': destinationName,
        'status': status,
        'startTime': startTime.toIso8601String(),
        'expectedDurationMinutes': expectedDurationMinutes,
        'lastKnownLat': lastKnownLocation.latitude,
        'lastKnownLng': lastKnownLocation.longitude,
        'routePoints': routePoints.map((p) => [p.latitude, p.longitude]).toList(),
        'lastCheckInStatus': lastCheckInStatus,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory PublicJourneySnapshot.fromJson(Map<String, dynamic> json) {
    final routeRaw = (json['routePoints'] as List? ?? []);
    final routeList = routeRaw.map((pt) {
      final list = pt as List;
      return LatLng((list[0] as num).toDouble(), (list[1] as num).toDouble());
    }).toList();

    return PublicJourneySnapshot(
      id: json['id'] as String,
      modeLabel: json['modeLabel'] as String,
      destinationName: json['destinationName'] as String,
      status: json['status'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      expectedDurationMinutes: (json['expectedDurationMinutes'] as num).toInt(),
      lastKnownLocation: LatLng(
        (json['lastKnownLat'] as num).toDouble(),
        (json['lastKnownLng'] as num).toDouble(),
      ),
      routePoints: routeList,
      lastCheckInStatus: json['lastCheckInStatus'] as String? ?? 'safe',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  static PublicJourneySnapshot fromJourney(Journey journey) {
    String checkInStatusStr = 'safe';
    if (journey.checkIns.isNotEmpty) {
      final last = journey.checkIns.last;
      if (last.classification != null) {
        checkInStatusStr = last.classification!.status.name;
      } else {
        checkInStatusStr = 'pending';
      }
    }

    return PublicJourneySnapshot(
      id: journey.id,
      modeLabel: journey.mode.label,
      destinationName: journey.destinationName,
      status: journey.status.name,
      startTime: journey.startTime,
      expectedDurationMinutes: journey.expectedDuration.inMinutes,
      lastKnownLocation: journey.currentPosition,
      routePoints: journey.routePoints,
      lastCheckInStatus: checkInStatusStr,
      lastUpdated: DateTime.now(),
    );
  }
}

class JourneySyncService {
  final StorageService _storage;
  static final StreamController<PublicJourneySnapshot> _broadcastController =
      StreamController<PublicJourneySnapshot>.broadcast();

  JourneySyncService(this._storage);

  /// Publishes a sanitized public snapshot to shared storage and live broadcast stream
  Future<void> publishJourney(Journey journey) async {
    final snapshot = PublicJourneySnapshot.fromJourney(journey);
    final key = 'gekko_public_journey_${journey.id}';
    final jsonStr = jsonEncode(snapshot.toJson());
    await _storage.prefs.setString(key, jsonStr);
    await _storage.prefs.setString('gekko_latest_public_journey_id', journey.id);

    _broadcastController.add(snapshot);
  }

  /// Fetches snapshot by journey ID from storage
  PublicJourneySnapshot? getSnapshot(String journeyId) {
    String? jsonStr = _storage.prefs.getString('gekko_public_journey_$journeyId');
    if (jsonStr == null || jsonStr.isEmpty) {
      // Fallback check latest
      final latestId = _storage.prefs.getString('gekko_latest_public_journey_id');
      if (latestId != null && latestId.isNotEmpty) {
        jsonStr = _storage.prefs.getString('gekko_public_journey_$latestId');
      }
    }
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return PublicJourneySnapshot.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  /// Live stream for public track view (polls local storage & listens to broadcast events)
  Stream<PublicJourneySnapshot?> streamSnapshot(String journeyId) async* {
    // Yield immediate value if available
    final initial = getSnapshot(journeyId);
    yield initial;

    // Periodically read storage to pick up updates across tabs/windows
    final timerStream = Stream.periodic(const Duration(seconds: 1), (_) => getSnapshot(journeyId));
    await for (final snap in timerStream) {
      yield snap;
    }
  }
}

final journeySyncServiceProvider = Provider<JourneySyncService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return JourneySyncService(storage);
});
