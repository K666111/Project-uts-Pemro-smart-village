
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> isLocationEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  static Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'GPS belum aktif. Silakan aktifkan lokasi perangkat.',
      );
    }

    final permission = await requestPermission();

    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan melalui pengaturan aplikasi.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (position.latitude == 0 && position.longitude == 0) {
        throw Exception(
          'Koordinat GPS emulator belum tersedia. Atur lokasi emulator terlebih dahulu.',
        );
      }

      return position;
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Gagal mengambil lokasi GPS: $error');
    }
  }

  static double calculateDistance({
    required double userLatitude,
    required double userLongitude,
    required double facilityLatitude,
    required double facilityLongitude,
  }) {
    return Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      facilityLatitude,
      facilityLongitude,
    );
  }

  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    }

    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  }
}
