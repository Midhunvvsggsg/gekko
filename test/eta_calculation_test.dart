import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:gekko/models/journey_mode_config.dart';
import 'package:gekko/utils/time_utils.dart';

void main() {
  group('Distance & Kolkata ETA Calculation Tests', () {
    test('calculateDistanceKm computes distance between coordinates accurately', () {
      final muvattupuzha = const LatLng(9.9836, 76.5786);
      final infopark = const LatLng(10.0088, 76.3680);

      final distKm = TimeUtils.calculateDistanceKm(muvattupuzha, infopark);

      expect(distKm, greaterThan(20.0));
      expect(distKm, lessThan(25.0));
    });

    test('JourneyModeConfig calculates estimated duration based on speed', () {
      final walkingMode = JourneyModeConfig.getById('walking'); // 5 km/h
      final taxiMode = JourneyModeConfig.getById('taxi'); // 35 km/h

      final distKm = 10.0;

      final walkingDuration = walkingMode.calculateEstimatedDuration(distKm);
      final taxiDuration = taxiMode.calculateEstimatedDuration(distKm);

      expect(walkingDuration.inMinutes, equals(120)); // 10 km @ 5 km/h = 2 hrs (120 mins)
      expect(taxiDuration.inMinutes, equals(17)); // 10 km @ 35 km/h ~ 17 mins
    });

    test('formatKolkataTime formats DateTime into IST 12-hour format', () {
      final utcTime = DateTime.utc(2026, 9, 18, 10, 0); // 10:00 UTC = 15:30 IST (03:30 PM IST)

      final formatted = TimeUtils.formatKolkataTime(utcTime);

      expect(formatted, equals('03:30 PM IST'));
    });
  });
}
