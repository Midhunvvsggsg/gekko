import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:gekko/services/speed_classifier_service.dart';
import 'package:gekko/services/journey_sync_service.dart';
import 'package:gekko/services/ai_service.dart';
import 'package:gekko/models/journey.dart';
import 'package:gekko/models/journey_mode_config.dart';
import 'package:gekko/models/check_in.dart';

void main() {
  group('Phase 4: SpeedClassifierService Tests', () {
    test('Walking speed returns walking band without mode switch', () {
      final classifier = SpeedClassifierService();
      final now = DateTime.now();

      classifier.addSample(const LatLng(37.7749, -122.4194), now.subtract(const Duration(seconds: 10)));
      classifier.addSample(const LatLng(37.7750, -122.4194), now);

      final result = classifier.evaluateCurrentSpeed();
      expect(result.currentBand, SpeedBand.walking);
      expect(result.shouldSwitchMode, false);
    });

    test('3 sustained vehicle speed readings trigger hysteresis mode switch to Bus', () {
      final classifier = SpeedClassifierService();
      final now = DateTime.now();

      // Sample 1 & 2: 200m in 2 seconds = 360 km/h (vehicle speed)
      classifier.addSample(const LatLng(37.7749, -122.4194), now.subtract(const Duration(seconds: 6)));
      classifier.addSample(const LatLng(37.7760, -122.4194), now.subtract(const Duration(seconds: 4)));
      classifier.evaluateCurrentSpeed();

      // Sample 3
      classifier.addSample(const LatLng(37.7770, -122.4194), now.subtract(const Duration(seconds: 2)));
      classifier.evaluateCurrentSpeed();

      // Sample 4
      classifier.addSample(const LatLng(37.7780, -122.4194), now);
      final result = classifier.evaluateCurrentSpeed();

      expect(result.shouldSwitchMode, true);
      expect(result.targetModeId, 'bus');
    });
  });

  group('Phase 4: PublicJourneySnapshot Serialization Tests', () {
    test('PublicJourneySnapshot to/from JSON matches exactly', () {
      final now = DateTime.now();
      final mode = JourneyModeConfig.defaultModes.first;

      final journey = Journey(
        id: 'test_123',
        mode: mode,
        destinationName: 'Central Station',
        destinationLatLng: const LatLng(37.7749, -122.4194),
        startTime: now,
        expectedDuration: const Duration(minutes: 15),
        currentPosition: const LatLng(37.7749, -122.4194),
      );

      final snapshot = PublicJourneySnapshot.fromJourney(journey);
      final jsonMap = snapshot.toJson();

      final restored = PublicJourneySnapshot.fromJson(jsonMap);
      expect(restored.id, 'test_123');
      expect(restored.destinationName, 'Central Station');
      expect(restored.modeLabel, mode.label);
      expect(restored.lastKnownLocation.latitude, 37.7749);
    });
  });

  group('Phase 4: Safety Classification Tests', () {
    test('Feeling uncomfortable someone behind me is classified as UNCERTAIN', () async {
      final aiService = AIService();
      final mode = JourneyModeConfig.defaultModes.first;

      final res = await aiService.classifyCheckInResponse(
        "Feeling a bit uncomfortable, someone behind me",
        "everything is fine",
        mode,
      );

      expect(res.status, CheckInStatus.uncertain);
    });
  });
}
