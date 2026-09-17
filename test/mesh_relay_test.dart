import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:gekko/models/journey.dart';
import 'package:gekko/models/journey_mode_config.dart';
import 'package:gekko/models/sos_hop_packet.dart';
import 'package:gekko/services/storage_service.dart';
import 'package:gekko/services/mesh_relay_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2P Delay-Tolerant Mesh Relay Tests', () {
    late StorageService storage;
    late MeshRelayService meshService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
      meshService = MeshRelayService(storage);
    });

    test('SosHopPacket serializes and deserializes cleanly', () {
      final now = DateTime.now();
      final packet = SosHopPacket(
        packetId: 'PKT-TEST-1',
        journeyId: 'JRN-101',
        originTimestamp: now,
        originLocation: const LatLng(12.9716, 77.5946),
        payloadSummary: 'Test SOS payload',
        status: SosHopStatus.offlineBroadcasting,
        hopCount: 0,
        hopHistory: [
          SosHopNode(
            nodeId: 'NODE-0',
            nodeLabel: 'User Device',
            nodeType: 'User Device',
            timestamp: now,
            position: const LatLng(12.9716, 77.5946),
          ),
        ],
      );

      final jsonMap = packet.toJson();
      final deserialized = SosHopPacket.fromJson(jsonMap);

      expect(deserialized.packetId, equals('PKT-TEST-1'));
      expect(deserialized.status, equals(SosHopStatus.offlineBroadcasting));
      expect(deserialized.hopCount, equals(0));
      expect(deserialized.hopHistory.length, equals(1));
    });

    test('MeshRelayService creates packet and simulates 3-hop device propagation', () async {
      final dummyJourney = Journey(
        id: 'jrn_test_mesh',
        mode: JourneyModeConfig.defaultModes.first,
        destinationName: 'Test Target',
        destinationLatLng: const LatLng(12.98, 77.60),
        expectedDuration: const Duration(minutes: 20),
        startTime: DateTime.now(),
        currentPosition: const LatLng(12.9716, 77.5946),
        routePoints: const [LatLng(12.9716, 77.5946)],
      );

      final packet = await meshService.createSosPacket(
        journey: dummyJourney,
        triggerSource: 'Manual Test Alarm',
      );

      expect(packet.hopCount, equals(0));
      expect(packet.status, equals(SosHopStatus.offlineBroadcasting));
      expect(packet.hopHistory.first.nodeType, equals('User Device'));

      // Simulate Hop 1: Moving vehicle
      final hop1 = await meshService.simulateHop();
      expect(hop1!.hopCount, equals(1));
      expect(hop1.status, equals(SosHopStatus.relaying));
      expect(hop1.hopHistory.last.nodeType, contains('Vehicle'));

      // Simulate Hop 2: Transit repeater
      final hop2 = await meshService.simulateHop();
      expect(hop2!.hopCount, equals(2));
      expect(hop2.status, equals(SosHopStatus.relaying));
      expect(hop2.hopHistory.last.nodeType, contains('Transit'));

      // Simulate Hop 3: Cellular Tower Gateway
      final hop3 = await meshService.simulateHop();
      expect(hop3!.hopCount, equals(3));
      expect(hop3.status, equals(SosHopStatus.towerDelivered));
      expect(hop3.hopHistory.last.nodeType, contains('Tower'));
    });
  });
}
