import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/journey.dart';
import '../models/sos_hop_packet.dart';
import '../providers/settings_provider.dart';
import 'storage_service.dart';

class MeshRelayService {
  final StorageService _storage;
  static const String _keyActivePacket = 'gekko_active_sos_mesh_packet';
  static const String _keyOfflineMeshMode = 'gekko_offline_mesh_mode';

  final StreamController<SosHopPacket?> _packetController =
      StreamController<SosHopPacket?>.broadcast();

  SosHopPacket? _currentPacket;
  bool _isOfflineMeshMode = false;

  MeshRelayService(this._storage) {
    _loadState();
  }

  void _loadState() {
    _isOfflineMeshMode = _storage.prefs.getBool(_keyOfflineMeshMode) ?? true;
    final jsonStr = _storage.prefs.getString(_keyActivePacket);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        _currentPacket = SosHopPacket.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        _currentPacket = null;
      }
    }
  }

  bool get isOfflineMeshMode => _isOfflineMeshMode;
  SosHopPacket? get activePacket => _currentPacket;
  Stream<SosHopPacket?> get packetStream => _packetController.stream;

  Future<void> setOfflineMeshMode(bool active) async {
    _isOfflineMeshMode = active;
    await _storage.prefs.setBool(_keyOfflineMeshMode, active);
  }

  /// Create a new SOS packet for offline P2P store-and-forward mesh dispatch
  Future<SosHopPacket> createSosPacket({
    required Journey journey,
    required String triggerSource,
  }) async {
    final now = DateTime.now();
    final originNode = SosHopNode(
      nodeId: 'NODE-USR-01',
      nodeLabel: 'User Device (Offline Host)',
      nodeType: 'User Device',
      timestamp: now,
      position: journey.currentPosition,
    );

    final contactsCount = _storage.getContacts().length;

    final packet = SosHopPacket(
      packetId: 'PKT-SOS-${now.millisecondsSinceEpoch.toString().substring(7)}',
      journeyId: journey.id,
      originTimestamp: now,
      originLocation: journey.currentPosition,
      payloadSummary: 'EMERGENCY SOS DISPATCH ($triggerSource) • ${journey.mode.label.toUpperCase()} • $contactsCount Contacts',
      status: SosHopStatus.offlineBroadcasting,
      hopCount: 0,
      hopHistory: [originNode],
    );

    _currentPacket = packet;
    await _savePacket(packet);
    _packetController.add(packet);
    return packet;
  }

  /// Simulate P2P device hopping (Device -> Moving Vehicle -> Transit Repeater -> Cell Tower)
  Future<SosHopPacket?> simulateHop() async {
    if (_currentPacket == null) return null;

    final packet = _currentPacket!;
    final now = DateTime.now();
    SosHopNode newNode;
    SosHopStatus newStatus = SosHopStatus.relaying;

    final originLat = packet.originLocation.latitude;
    final originLng = packet.originLocation.longitude;

    if (packet.hopCount == 0) {
      // Hop 1: Relayed via nearby moving vehicle / passerby BLE
      newNode = SosHopNode(
        nodeId: 'NODE-VHL-402',
        nodeLabel: 'Honda Civic (BLE Mesh Relay Node #402)',
        nodeType: 'Moving Vehicle (BLE Node)',
        timestamp: now,
        position: LatLng(originLat + 0.0018, originLng + 0.0022),
      );
    } else if (packet.hopCount == 1) {
      // Hop 2: Relayed via municipal transit repeater node
      newNode = SosHopNode(
        nodeId: 'NODE-TRN-88',
        nodeLabel: 'Transit Repeater Node #88 (V2X Gateway)',
        nodeType: 'Transit Hub Repeater',
        timestamp: now,
        position: LatLng(originLat + 0.0045, originLng + 0.0051),
      );
    } else {
      // Hop 3: Reached internet-connected Cellular Tower Node
      newNode = SosHopNode(
        nodeId: 'NODE-TWR-04B',
        nodeLabel: 'Cellular Tower Gateway (Tower #04-B)',
        nodeType: 'Cellular Gateway Tower',
        timestamp: now,
        position: LatLng(originLat + 0.0080, originLng + 0.0095),
      );
      newStatus = SosHopStatus.towerDelivered;
    }

    final updatedHistory = List<SosHopNode>.from(packet.hopHistory)..add(newNode);

    final updatedPacket = packet.copyWith(
      status: newStatus,
      hopCount: packet.hopCount + 1,
      hopHistory: updatedHistory,
    );

    _currentPacket = updatedPacket;
    await _savePacket(updatedPacket);
    _packetController.add(updatedPacket);
    return updatedPacket;
  }

  Future<void> clearActivePacket() async {
    _currentPacket = null;
    await _storage.prefs.remove(_keyActivePacket);
    _packetController.add(null);
  }

  Future<void> _savePacket(SosHopPacket packet) async {
    await _storage.prefs.setString(_keyActivePacket, jsonEncode(packet.toJson()));
  }
}

final meshRelayServiceProvider = Provider<MeshRelayService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MeshRelayService(storage);
});
