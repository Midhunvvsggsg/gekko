import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journey.dart';
import '../models/sos_hop_packet.dart';
import '../services/mesh_relay_service.dart';

class MeshRelayState {
  final bool isOfflineMeshActive;
  final SosHopPacket? activePacket;

  const MeshRelayState({
    required this.isOfflineMeshActive,
    this.activePacket,
  });

  MeshRelayState copyWith({
    bool? isOfflineMeshActive,
    SosHopPacket? activePacket,
    bool clearPacket = false,
  }) {
    return MeshRelayState(
      isOfflineMeshActive: isOfflineMeshActive ?? this.isOfflineMeshActive,
      activePacket: clearPacket ? null : (activePacket ?? this.activePacket),
    );
  }
}

class MeshRelayNotifier extends StateNotifier<MeshRelayState> {
  final MeshRelayService _meshService;

  MeshRelayNotifier(this._meshService)
      : super(MeshRelayState(
          isOfflineMeshActive: _meshService.isOfflineMeshMode,
          activePacket: _meshService.activePacket,
        )) {
    _meshService.packetStream.listen((packet) {
      state = state.copyWith(activePacket: packet, clearPacket: packet == null);
    });
  }

  Future<void> toggleOfflineMesh(bool active) async {
    await _meshService.setOfflineMeshMode(active);
    state = state.copyWith(isOfflineMeshActive: active);
  }

  Future<SosHopPacket> initSosPacket(Journey journey, String triggerSource) async {
    final packet = await _meshService.createSosPacket(
      journey: journey,
      triggerSource: triggerSource,
    );
    state = state.copyWith(activePacket: packet);
    return packet;
  }

  Future<void> simulateHop() async {
    final updated = await _meshService.simulateHop();
    if (updated != null) {
      state = state.copyWith(activePacket: updated);
    }
  }

  Future<void> clearPacket() async {
    await _meshService.clearActivePacket();
    state = state.copyWith(clearPacket: true);
  }
}

final meshRelayProvider = StateNotifierProvider<MeshRelayNotifier, MeshRelayState>((ref) {
  final service = ref.watch(meshRelayServiceProvider);
  return MeshRelayNotifier(service);
});
