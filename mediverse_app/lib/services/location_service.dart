import 'package:geolocator/geolocator.dart';

class LocationService {
  // Default mock location coordinates (Bangalore center)
  static const double defaultLat = 12.9716;
  static const double defaultLng = 77.5946;

  static bool isMocked = true; // Set to true by default for developer emulation safety
  static double currentMockLat = defaultLat;
  static double currentMockLng = defaultLng;

  static Future<Map<String, double>> getCurrentCoordinates() async {
    if (isMocked) {
      return {"lat": currentMockLat, "lng": currentMockLng};
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {"lat": defaultLat, "lng": defaultLng};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {"lat": defaultLat, "lng": defaultLng};
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      
      return {"lat": position.latitude, "lng": position.longitude};
    } catch (e) {
      // Fallback if geolocator fails (e.g. emulator has no active GPS providers)
      return {"lat": defaultLat, "lng": defaultLng};
    }
  }

  // Set new coordinates for simulation mode
  static void setSimulatedLocation(double lat, double lng) {
    isMocked = true;
    currentMockLat = lat;
    currentMockLng = lng;
  }
}
