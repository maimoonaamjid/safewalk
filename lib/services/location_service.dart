import 'package:geolocator/geolocator.dart';

/// Wraps the geolocator package so the rest of the app stays simple.
class LocationService {
  static bool _asked = false;

  /// Shows the Android permission dialog once per app launch.
  static Future<void> requestPermissionIfNeeded() async {
    if (_asked) return;
    _asked = true;
    try {
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {}
  }

  /// Returns the current position, or null if it cannot be found.
  static Future<Position?> getCurrent() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return await _lastKnown();
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      // Timeout or error: fall back to the last position the phone knows.
      return await _lastKnown();
    }
  }

  static Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }
}
