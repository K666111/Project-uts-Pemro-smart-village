import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/notification_service.dart';
import '../data/facility_data.dart';
import '../models/facility.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../utils/app_colors.dart';

class MapPage extends StatefulWidget {
  final Facility? selectedFacility;

  const MapPage({super.key, this.selectedFacility});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();

  static const double proximityRadius = 500;
  static const double rearmRadius = 600;

  StreamSubscription<Position>? positionSubscription;

  final Set<String> notifiedFacilityIds = {};

  LatLng? userLocation;
  Facility? selectedFacility;

  RouteResult? routeResult;

  String transportMode = 'car';

  bool isLoadingLocation = true;
  bool isLoadingRoute = false;

  String? locationError;
  String? routeError;

  @override
  void initState() {
    super.initState();

    selectedFacility = widget.selectedFacility;

    _startProximityMonitoring();
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  List<Facility> get facilities {
    return FacilityData.facilities.where((facility) {
      return facility.latitude != null && facility.longitude != null;
    }).toList();
  }

  LatLng get initialMapCenter {
    if (selectedFacility != null &&
        selectedFacility!.latitude != null &&
        selectedFacility!.longitude != null) {
      return LatLng(selectedFacility!.latitude!, selectedFacility!.longitude!);
    }

    return const LatLng(-6.1754, 106.8272);
  }

  // Memulai pemantauan lokasi dan notifikasi.
  Future<void> _startProximityMonitoring() async {
    try {
      await NotificationService.requestPermission();

      final position = await LocationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);

        isLoadingLocation = false;
        locationError = null;
      });

      await _checkNearbyFacilities(position);

      if (!mounted) return;

      positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 50,
            ),
          ).listen(
            (Position position) {
              _handlePositionUpdate(position);
            },
            onError: (error) {
              if (!mounted) return;

              setState(() {
                locationError = 'Pemantauan GPS terganggu: $error';
              });
            },
          );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
        locationError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Memperbarui lokasi pengguna ketika GPS berubah.
  Future<void> _handlePositionUpdate(Position position) async {
    if (!mounted) return;

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    await _checkNearbyFacilities(position);
  }

  // Memeriksa jarak pengguna dengan setiap fasilitas.
  Future<void> _checkNearbyFacilities(Position position) async {
    for (final facility in facilities) {
      if (facility.latitude == null || facility.longitude == null) {
        continue;
      }

      final distance = LocationService.calculateDistance(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        facilityLatitude: facility.latitude!,
        facilityLongitude: facility.longitude!,
      );

      if (distance > rearmRadius) {
        notifiedFacilityIds.remove(facility.id);
        continue;
      }

      if (distance <= proximityRadius &&
          !notifiedFacilityIds.contains(facility.id)) {
        notifiedFacilityIds.add(facility.id);

        try {
          await NotificationService.showNotification(
            id: facility.id.hashCode & 0x7fffffff,
            title: 'Fasilitas Kesehatan Terdekat',
            body:
                '${facility.name} berada sekitar '
                '${LocationService.formatDistance(distance)} '
                'dari lokasi Anda.',
          );
        } catch (error) {
          debugPrint('Gagal mengirim notifikasi: $error');
        }
      }
    }
  }

  // Mengambil lokasi GPS terbaru.
  Future<void> _loadUserLocation() async {
    setState(() {
      isLoadingLocation = true;
      locationError = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);

        isLoadingLocation = false;
        locationError = null;
      });

      mapController.move(userLocation!, 16);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
        locationError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Membuat rute di dalam aplikasi.
  Future<void> _buildRoute() async {
    if (selectedFacility == null) {
      setState(() {
        routeError = 'Pilih fasilitas kesehatan terlebih dahulu.';
      });
      return;
    }

    if (selectedFacility!.latitude == null ||
        selectedFacility!.longitude == null) {
      setState(() {
        routeError = 'Koordinat tujuan belum tersedia.';
      });
      return;
    }

    if (userLocation == null) {
      await _loadUserLocation();
    }

    if (!mounted) return;

    if (userLocation == null) {
      setState(() {
        routeError = 'Lokasi pengguna belum tersedia.';
      });
      return;
    }

    setState(() {
      isLoadingRoute = true;
      routeError = null;
      routeResult = null;
    });

    try {
      final destination = LatLng(
        selectedFacility!.latitude!,
        selectedFacility!.longitude!,
      );

      final result = await RouteService.getRoute(
        origin: userLocation!,
        destination: destination,
        transportMode: transportMode,
      );

      if (!mounted) return;

      setState(() {
        routeResult = result;
        isLoadingRoute = false;
      });

      if (result.points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(result.points);

        mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(65)),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingRoute = false;

        routeError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Membuka navigasi menggunakan aplikasi Google Maps.

  Future<void> _openGoogleMapsNavigation() async {
    if (selectedFacility == null ||
        selectedFacility!.latitude == null ||
        selectedFacility!.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi tujuan belum tersedia.')),
      );
      return;
    }

    final latitude = selectedFacility!.latitude!;
    final longitude = selectedFacility!.longitude!;

    final travelMode = transportMode == 'walking' ? 'walking' : 'driving';

    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': travelMode,
      'dir_action': 'navigate',
    });

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!mounted) return;

      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak dapat membuka Google Maps. Periksa instalasi Google Maps dan browser emulator.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka navigasi: $error')));
    }
  }

  // Memilih fasilitas sebagai tujuan.
  void _selectFacility(Facility facility) {
    setState(() {
      selectedFacility = facility;
      routeResult = null;
      routeError = null;
    });

    if (facility.latitude != null && facility.longitude != null) {
      mapController.move(LatLng(facility.latitude!, facility.longitude!), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Peta Lokasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadUserLocation,
            tooltip: 'Perbarui lokasi',
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: initialMapCenter,
              initialZoom: selectedFacility != null ? 15 : 12,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smart_village_uts',
              ),

              if (routeResult != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routeResult!.points,
                      strokeWidth: 5,
                      color: AppColors.primary,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: facilities.map((facility) {
                  final isSelected = facility.id == selectedFacility?.id;

                  return Marker(
                    point: LatLng(facility.latitude!, facility.longitude!),
                    width: 55,
                    height: 65,
                    child: GestureDetector(
                      onTap: () {
                        _showFacilityInfo(context, facility);
                      },
                      child: Icon(
                        Icons.location_on,
                        color: isSelected
                            ? Colors.orange
                            : _getCategoryColor(facility.category),
                        size: isSelected ? 52 : 45,
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation!,
                      width: 45,
                      height: 45,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 27,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${facilities.length} fasilitas kesehatan ditampilkan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: _buildRoutePanel(),
          ),

          if (userLocation != null)
            Positioned(
              right: 16,
              bottom: 270,
              child: FloatingActionButton.small(
                heroTag: 'my_location_map_button',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                onPressed: () {
                  mapController.move(userLocation!, 16);
                },
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }

  // Panel informasi dan pilihan rute.
  Widget _buildRoutePanel() {
    return Card(
      elevation: 5,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rute Perjalanan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 10),

            if (selectedFacility != null)
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedFacility!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'Pilih fasilitas pada peta untuk menentukan tujuan.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _transportButton(
                    mode: 'car',
                    label: 'Mobil',
                    icon: Icons.directions_car,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _transportButton(
                    mode: 'motorcycle',
                    label: 'Motor',
                    icon: Icons.two_wheeler,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _transportButton(
                    mode: 'walking',
                    label: 'Jalan',
                    icon: Icons.directions_walk,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (isLoadingLocation)
              const Text(
                'Mengambil lokasi pengguna...',
                style: TextStyle(fontSize: 12),
              )
            else if (locationError != null)
              Text(
                locationError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),

            if (routeResult != null) ...[
              const Divider(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _routeInformation(
                      Icons.route,
                      'Jarak',
                      routeResult!.formattedDistance,
                    ),
                  ),
                  Expanded(
                    child: _routeInformation(
                      Icons.access_time,
                      'Estimasi waktu',
                      routeResult!.formattedDuration,
                    ),
                  ),
                ],
              ),

              if (transportMode == 'motorcycle')
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Catatan: Rute motor menggunakan profil mobil sebagai perkiraan.',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],

            if (routeError != null) ...[
              const SizedBox(height: 8),
              Text(
                routeError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],

            const SizedBox(height: 12),

            // Tombol untuk menampilkan rute di aplikasi.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoadingRoute || selectedFacility == null
                    ? null
                    : _buildRoute,
                icon: isLoadingRoute
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.alt_route),
                label: Text(
                  isLoadingRoute ? 'Mencari rute...' : 'Tampilkan Rute',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),

            // Tombol untuk membuka navigasi Google Maps.
            if (selectedFacility != null) ...[
              const SizedBox(height: 9),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openGoogleMapsNavigation,
                  icon: const Icon(Icons.navigation, size: 20),
                  label: const Text('Navigasi dengan Google Maps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              // TOMBOL MULAI NAVIGASI GOOGLE MAPS
              if (routeResult != null) ...[
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openGoogleMapsNavigation,
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Mulai Navigasi Google Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _transportButton({
    required String mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = transportMode == mode;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          transportMode = mode;
          routeResult = null;
          routeError = null;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        backgroundColor: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.white,
        foregroundColor: isSelected
            ? AppColors.primary
            : AppColors.textSecondary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _routeInformation(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Rumah Sakit':
        return Colors.red;
      case 'Puskesmas':
        return Colors.green;
      case 'Klinik':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  // Menampilkan informasi fasilitas ketika marker dipilih.
  void _showFacilityInfo(BuildContext context, Facility facility) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                facility.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                facility.category,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(facility.address),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 19),
                  const SizedBox(width: 5),
                  Text('${facility.rating} (${facility.reviewCount} ulasan)'),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _selectFacility(facility);
                  },
                  icon: const Icon(Icons.flag),
                  label: const Text('Pilih sebagai Tujuan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
