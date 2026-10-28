import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants.dart';

class UserLocation {
  final double lat;
  final double lon;
  final String name;
  final bool isFallback;
  const UserLocation({required this.lat, required this.lon, required this.name, this.isFallback = false});
}

/// PRD FR-1: GPS + fallback Jakarta bila deny/timeout.
class LocationService {
  Future<UserLocation> current() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return const UserLocation(
          lat: AppConstants.fallbackLat,
          lon: AppConstants.fallbackLon,
          name: AppConstants.fallbackName,
          isFallback: true,
        );
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      String name = 'Lokasi saya';
      try {
        final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (marks.isNotEmpty) {
          name = marks.first.locality?.isNotEmpty == true
              ? marks.first.locality!
              : (marks.first.subAdministrativeArea ?? name);
        }
      } catch (_) {}
      return UserLocation(lat: pos.latitude, lon: pos.longitude, name: name);
    } catch (_) {
      return const UserLocation(
        lat: AppConstants.fallbackLat,
        lon: AppConstants.fallbackLon,
        name: AppConstants.fallbackName,
        isFallback: true,
      );
    }
  }
}
