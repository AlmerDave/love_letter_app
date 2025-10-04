import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request location permission from user
  static Future<bool> requestLocationPermission() async {
    // Step 1: Check if location services are enabled on device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled
      print('📍 Location services are disabled');
      return false;
    }

    // Step 2: Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Permission not granted yet, ask user
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('📍 Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied
      print('📍 Location permission denied forever');
      return false;
    }

    // Permission granted!
    print('✅ Location permission granted');
    return true;
  }

  /// Get current device location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Step 1: Request permission first
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('❌ No location permission');
        return null;
      }

      // Step 2: Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,  // Best accuracy
      );

      print('📍 Got location: ${position.latitude}, ${position.longitude}');
      return position;

    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Get distance between two coordinates (in meters)
  static double getDistanceBetween({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}