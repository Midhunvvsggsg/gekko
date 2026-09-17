import 'package:latlong2/latlong.dart';

enum SpeedBand {
  walking,
  transitional,
  vehicle,
}

class LocationSample {
  final LatLng position;
  final DateTime timestamp;

  LocationSample(this.position, this.timestamp);
}

class SpeedClassifierResult {
  final double currentSpeedKmh;
  final SpeedBand currentBand;
  final bool shouldSwitchMode;
  final String targetModeId; // 'bus'

  SpeedClassifierResult({
    required this.currentSpeedKmh,
    required this.currentBand,
    required this.shouldSwitchMode,
    required this.targetModeId,
  });
}

class SpeedClassifierService {
  final List<LocationSample> _samples = [];
  final List<SpeedBand> _recentBands = [];
  static const Distance _distanceCalculator = Distance();

  void addSample(LatLng position, DateTime timestamp) {
    _samples.add(LocationSample(position, timestamp));
    if (_samples.length > 5) {
      _samples.removeAt(0);
    }
  }

  SpeedClassifierResult evaluateCurrentSpeed() {
    if (_samples.length < 2) {
      return SpeedClassifierResult(
        currentSpeedKmh: 0.0,
        currentBand: SpeedBand.walking,
        shouldSwitchMode: false,
        targetModeId: 'walk',
      );
    }

    final latest = _samples.last;
    final previous = _samples[_samples.length - 2];

    final meters = _distanceCalculator.as(LengthUnit.Meter, previous.position, latest.position);
    final seconds = latest.timestamp.difference(previous.timestamp).inSeconds.clamp(1, 3600);

    // Calculate km/h
    final speedKmh = (meters / seconds) * 3.6;

    SpeedBand band = SpeedBand.walking;
    if (speedKmh >= 15.0) {
      band = SpeedBand.vehicle;
    } else if (speedKmh >= 8.0) {
      band = SpeedBand.transitional;
    } else {
      band = SpeedBand.walking;
    }

    _recentBands.add(band);
    if (_recentBands.length > 5) {
      _recentBands.removeAt(0);
    }

    // Require 3 consecutive vehicle band readings (hysteresis)
    bool confirmedVehicle = false;
    if (_recentBands.length >= 3) {
      final lastThree = _recentBands.sublist(_recentBands.length - 3);
      confirmedVehicle = lastThree.every((b) => b == SpeedBand.vehicle);
    }

    return SpeedClassifierResult(
      currentSpeedKmh: speedKmh,
      currentBand: band,
      shouldSwitchMode: confirmedVehicle,
      targetModeId: 'bus',
    );
  }

  void reset() {
    _samples.clear();
    _recentBands.clear();
  }
}
