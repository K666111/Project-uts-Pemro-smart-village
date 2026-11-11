import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distance;
  final double duration;

  const RouteResult({
    required this.points,
    required this.distance,
    required this.duration,
  });

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    }

    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final totalMinutes = (duration / 60).round();

    if (totalMinutes < 60) {
      return '$totalMinutes menit';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (minutes == 0) {
      return '$hours jam';
    }

    return '$hours jam $minutes menit';
  }
}

class RouteService {
  static Future<RouteResult> getRoute({
    required LatLng origin,
    required LatLng destination,
    required String transportMode,
  }) async {
    // Validasi koordinat asal dan tujuan.
    if (!_isValidCoordinate(origin) || !_isValidCoordinate(destination)) {
      throw Exception('Koordinat lokasi pengguna atau tujuan tidak valid.');
    }

    // OSRM demo menggunakan profil driving.
    // Profil foot dan cycling belum tentu tersedia
    // pada server demo yang digunakan.
    if (transportMode == 'walking' || transportMode == 'cycling') {
      throw Exception(
        'Rute jalan kaki dan sepeda belum didukung '
        'oleh server OSRM yang digunakan.',
      );
    }

    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';

    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coordinates',
      {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
    );

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Server rute memberikan HTTP '
          '${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception('Format respons server tidak valid.');
      }

      if (data['code'] != 'Ok') {
        throw Exception(
          'Rute tidak ditemukan: ${data['message'] ?? data['code']}',
        );
      }

      final routes = data['routes'];

      if (routes is! List || routes.isEmpty) {
        throw Exception('Tidak ada rute yang ditemukan.');
      }

      final route = routes.first;
      final geometry = route['geometry'];
      final coordinatesList = geometry['coordinates'];

      if (coordinatesList is! List || coordinatesList.isEmpty) {
        throw Exception('Data koordinat rute kosong.');
      }

      final points = coordinatesList.map<LatLng>((coordinate) {
        return LatLng(
          (coordinate[1] as num).toDouble(),
          (coordinate[0] as num).toDouble(),
        );
      }).toList();

      return RouteResult(
        points: points,
        distance: (route['distance'] as num).toDouble(),
        duration: (route['duration'] as num).toDouble(),
      );
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }

      throw Exception('Terjadi kesalahan saat memproses rute: $error');
    }
  }

  static bool _isValidCoordinate(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }
}
