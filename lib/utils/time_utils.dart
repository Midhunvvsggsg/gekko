import 'package:latlong2/latlong.dart';

class TimeUtils {
  /// Converts any DateTime to Kolkata Time Zone (IST, UTC+5:30)
  static DateTime toKolkataTime(DateTime dt) {
    final utc = dt.toUtc();
    return utc.add(const Duration(hours: 5, minutes: 30));
  }

  /// Formats DateTime into 12-hour Kolkata Time (e.g. "05:45 PM IST")
  static String formatKolkataTime(DateTime dt) {
    final ist = toKolkataTime(dt);
    final hour = ist.hour;
    final minute = ist.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = (hour % 12 == 0 ? 12 : hour % 12).toString().padLeft(2, '0');
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period IST';
  }

  /// Calculates geodesic distance between two LatLng points in kilometers
  static double calculateDistanceKm(LatLng start, LatLng end) {
    const distanceCalculator = Distance();
    final meters = distanceCalculator.as(LengthUnit.Meter, start, end);
    return meters / 1000.0;
  }
}
