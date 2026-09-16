import 'package:latlong2/latlong.dart';

class LocationService {
  // Demo coordinates centered around a city (e.g. San Francisco downtown)
  static const LatLng defaultStart = LatLng(37.7749, -122.4194);
  static const LatLng destinationSF1 = LatLng(37.7833, -122.4167); // Union Square area
  static const LatLng destinationSF2 = LatLng(37.7600, -122.4100); // Mission District
  static const LatLng destinationSF3 = LatLng(37.7890, -122.4014); // Embarcadero

  static List<LatLng> generateMockRoute(LatLng start, LatLng end, {int steps = 20}) {
    List<LatLng> points = [];
    double deltaLat = (end.latitude - start.latitude) / steps;
    double deltaLng = (end.longitude - start.longitude) / steps;

    for (int i = 0; i <= steps; i++) {
      // Add slight natural curve jitter
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
      current.latitude + 0.005, // Sharp off-route shift (~500m)
      current.longitude - 0.006,
    );
  }
}
