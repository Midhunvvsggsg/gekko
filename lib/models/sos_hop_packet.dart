import 'package:latlong2/latlong.dart';

enum SosHopStatus {
  offlineBroadcasting,
  relaying,
  towerDelivered,
}

class SosHopNode {
  final String nodeId;
  final String nodeLabel;
  final String nodeType; // 'User Device', 'Moving Vehicle (BLE)', 'Transit Hub Node', 'Cellular Gateway Tower'
  final DateTime timestamp;
  final LatLng? position;

  SosHopNode({
    required this.nodeId,
    required this.nodeLabel,
    required this.nodeType,
    required this.timestamp,
    this.position,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'nodeLabel': nodeLabel,
        'nodeType': nodeType,
        'timestamp': timestamp.toIso8601String(),
        'lat': position?.latitude,
        'lng': position?.longitude,
      };

  factory SosHopNode.fromJson(Map<String, dynamic> json) {
    LatLng? pos;
    if (json['lat'] != null && json['lng'] != null) {
      pos = LatLng((json['lat'] as num).toDouble(), (json['lng'] as num).toDouble());
    }
    return SosHopNode(
      nodeId: json['nodeId'] as String,
      nodeLabel: json['nodeLabel'] as String,
      nodeType: json['nodeType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      position: pos,
    );
  }
}

class SosHopPacket {
  final String packetId;
  final String journeyId;
  final DateTime originTimestamp;
  final LatLng originLocation;
  final String payloadSummary;
  final SosHopStatus status;
  final int hopCount;
  final List<SosHopNode> hopHistory;

  SosHopPacket({
    required this.packetId,
    required this.journeyId,
    required this.originTimestamp,
    required this.originLocation,
    required this.payloadSummary,
    required this.status,
    required this.hopCount,
    required this.hopHistory,
  });

  SosHopPacket copyWith({
    SosHopStatus? status,
    int? hopCount,
    List<SosHopNode>? hopHistory,
  }) {
    return SosHopPacket(
      packetId: packetId,
      journeyId: journeyId,
      originTimestamp: originTimestamp,
      originLocation: originLocation,
      payloadSummary: payloadSummary,
      status: status ?? this.status,
      hopCount: hopCount ?? this.hopCount,
      hopHistory: hopHistory ?? List.from(this.hopHistory),
    );
  }

  Map<String, dynamic> toJson() => {
        'packetId': packetId,
        'journeyId': journeyId,
        'originTimestamp': originTimestamp.toIso8601String(),
        'originLat': originLocation.latitude,
        'originLng': originLocation.longitude,
        'payloadSummary': payloadSummary,
        'status': status.name,
        'hopCount': hopCount,
        'hopHistory': hopHistory.map((h) => h.toJson()).toList(),
      };

  factory SosHopPacket.fromJson(Map<String, dynamic> json) {
    final historyRaw = (json['hopHistory'] as List? ?? []);
    final history = historyRaw.map((item) => SosHopNode.fromJson(item as Map<String, dynamic>)).toList();

    return SosHopPacket(
      packetId: json['packetId'] as String,
      journeyId: json['journeyId'] as String,
      originTimestamp: DateTime.parse(json['originTimestamp'] as String),
      originLocation: LatLng(
        (json['originLat'] as num).toDouble(),
        (json['originLng'] as num).toDouble(),
      ),
      payloadSummary: json['payloadSummary'] as String,
      status: SosHopStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SosHopStatus.offlineBroadcasting,
      ),
      hopCount: (json['hopCount'] as num).toInt(),
      hopHistory: history,
    );
  }
}
