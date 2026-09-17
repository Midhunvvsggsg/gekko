import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationSearchResult {
  final String name;
  final String description;
  final LatLng latLng;

  LocationSearchResult({
    required this.name,
    required this.description,
    required this.latLng,
  });
}

class LocationService {
  // Demo coordinates centered around San Francisco
  static const LatLng defaultStart = LatLng(37.7749, -122.4194);
  static const LatLng destinationSF1 = LatLng(37.7833, -122.4167); // Union Square area
  static const LatLng destinationSF2 = LatLng(37.7600, -122.4100); // Mission District
  static const LatLng destinationSF3 = LatLng(37.7890, -122.4014); // Embarcadero

  /// Real-time place autocomplete search (Photon / OpenStreetMap Geocoding API)
  static Future<List<LocationSearchResult>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(cleanQuery)}&limit=5',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List features = data['features'] ?? [];

        return features.map<LocationSearchResult>((f) {
          final props = f['properties'] ?? {};
          final coords = f['geometry']?['coordinates'] ?? [ -122.4194, 37.7749 ];
          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();

          final name = props['name']?.toString() ?? cleanQuery;
          final city = props['city']?.toString() ?? props['state']?.toString() ?? props['country']?.toString() ?? '';
          final desc = city.isNotEmpty ? '$name, $city' : name;

          return LocationSearchResult(
            name: name,
            description: desc,
            latLng: LatLng(lat, lng),
          );
        }).toList();
      }
    } catch (_) {
      // Fallback on search timeout/offline
    }

    // Local fallback suggestions matching query
    final presets = [
      LocationSearchResult(name: 'Union Square, SF', description: 'Union Square, San Francisco, CA', latLng: destinationSF1),
      LocationSearchResult(name: 'Mission District, SF', description: 'Mission District, San Francisco, CA', latLng: destinationSF2),
      LocationSearchResult(name: 'Embarcadero Pier, SF', description: 'Embarcadero Pier, San Francisco, CA', latLng: destinationSF3),
      LocationSearchResult(name: 'Financial District, SF', description: 'Financial District, San Francisco, CA', latLng: const LatLng(37.7946, -122.3999)),
      LocationSearchResult(name: 'Central Train Station', description: 'Central Station Terminal', latLng: const LatLng(37.7766, -122.3942)),
    ];

    return presets.where((p) => p.description.toLowerCase().contains(cleanQuery.toLowerCase())).toList();
  }

  static List<LatLng> generateMockRoute(LatLng start, LatLng end, {int steps = 20}) {
    List<LatLng> points = [];
    double deltaLat = (end.latitude - start.latitude) / steps;
    double deltaLng = (end.longitude - start.longitude) / steps;

    for (int i = 0; i <= steps; i++) {
      double curve = (i > 0 && i < steps) ? (i % 2 == 0 ? 0.0008 : -0.0008) : 0.0;
      points.add(LatLng(
        start.latitude + (deltaLat * i) + curve,
        start.longitude + (deltaLng * i),
      ));
    }
    return points;
  }

  static LatLng generateDeviatedPoint(LatLng current) {
    return LatLng(
      current.latitude + 0.005,
      current.longitude - 0.006,
    );
  }
}
