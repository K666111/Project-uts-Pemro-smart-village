
import 'package:flutter/material.dart';

import 'detail_page.dart';
import '../data/facility_data.dart';
import '../models/facility.dart';
import '../services/favorite_service.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';
import 'facility_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController =
  TextEditingController();

  String selectedCategory = 'Semua';

  bool isLoadingLocation = false;
  bool locationReady = false;
  String? locationError;

  bool isLoadingFavorites = true;
  final Set<String> favoriteIds = {};

  final Map<String, double> facilityDistances = {};

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Rumah Sakit',
      'icon': Icons.local_hospital,
      'color': Colors.red,
    },
    {
      'name': 'Puskesmas',
      'icon': Icons.medical_services,
      'color': Colors.green,
    },
    {
      'name': 'Klinik',
      'icon': Icons.health_and_safety,
      'color': Colors.blue,
    },
    {
      'name': 'Semua',
      'icon': Icons.grid_view,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoriteService.getFavorites();

    if (!mounted) return;

    setState(() {
      favoriteIds
        ..clear()
        ..addAll(favorites);
      isLoadingFavorites = false;
    });
  }

  Future<void> _toggleFavorite(Facility facility) async {
    await FavoriteService.toggleFavorite(facility.id);

    if (!mounted) return;

    setState(() {
      if (favoriteIds.contains(facility.id)) {
        favoriteIds.remove(facility.id);
      } else {
        favoriteIds.add(facility.id);
      }
    });

    final isFavorite = favoriteIds.contains(facility.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? '${facility.name} ditambahkan ke Favorit.'
              : '${facility.name} dihapus dari Favorit.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadUserLocation() async {
    if (isLoadingLocation) return;

    setState(() {
      isLoadingLocation = true;
      locationError = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      final distances = <String, double>{};

      for (final facility in FacilityData.facilities) {
        if (facility.latitude == null ||
            facility.longitude == null) {
          continue;
        }

        distances[facility.id] =
            LocationService.calculateDistance(
              userLatitude: position.latitude,
              userLongitude: position.longitude,
              facilityLatitude: facility.latitude!,
              facilityLongitude: facility.longitude!,
            );
      }

      if (!mounted) return;

      setState(() {
        facilityDistances
          ..clear()
          ..addAll(distances);

        locationReady = true;
        isLoadingLocation = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        locationReady = false;
        isLoadingLocation = false;
        locationError = error.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  List<Facility> get filteredFacilities {
    final keyword = searchController.text.toLowerCase().trim();

    final result = FacilityData.facilities.where((facility) {
      final matchesCategory = selectedCategory == 'Semua' ||
          facility.category == selectedCategory;

      final matchesSearch =
          facility.name.toLowerCase().contains(keyword) ||
              facility.address.toLowerCase().contains(keyword);

      return matchesCategory && matchesSearch;
    }).toList();

    if (locationReady) {
      result.sort((a, b) {
        final distanceA = facilityDistances[a.id];
        final distanceB = facilityDistances[b.id];

        if (distanceA == null && distanceB == null) return 0;
        if (distanceA == null) return 1;
        if (distanceB == null) return -1;

        return distanceA.compareTo(distanceB);
      });
    }

    return result;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facilities = filteredFacilities;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 27,
            ),
            const SizedBox(width: 6),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Village',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'Kabupaten X',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Fitur notifikasi akan kita aktifkan pada tahap berikutnya.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pencarian
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari rumah sakit, puskesmas, klinik...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Status GPS
            _locationStatus(),

            const SizedBox(height: 24),

            // Kategori
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kategori Fasilitas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FacilityPage(),
                      ),
                    );
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: categories.map((category) {
                final isSelected =
                    selectedCategory == category['name'];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category['name'];
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: category['color']
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? category['color']
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            category['icon'],
                            color: category['color'],
                            size: 27,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          category['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 26),

            // Fasilitas terdekat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Layanan Kesehatan Terdekat',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FacilityPage(),
                      ),
                    );
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (facilities.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Fasilitas tidak ditemukan.'),
                ),
              )
            else
              ...facilities.map(
                    (facility) => _facilityCard(facility),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Informasi status lokasi pengguna
  Widget _locationStatus() {
    String message;
    IconData icon;
    Color color;

    if (isLoadingLocation) {
      message = 'Sedang mengambil lokasi pengguna...';
      icon = Icons.location_searching;
      color = Colors.orange;
    } else if (locationReady) {
      message =
      'Lokasi berhasil ditemukan. Fasilitas diurutkan berdasarkan jarak.';
      icon = Icons.my_location;
      color = Colors.green;
    } else {
      message = locationError ?? 'Lokasi belum tersedia.';
      icon = Icons.location_off;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ),
          if (!isLoadingLocation)
            IconButton(
              onPressed: _loadUserLocation,
              tooltip: 'Perbarui lokasi',
              icon: Icon(
                Icons.refresh,
                color: color,
              ),
            )
          else
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  // Kartu fasilitas kesehatan
  Widget _facilityCard(Facility facility) {
    final distance = facilityDistances[facility.id];
    final isFavorite = favoriteIds.contains(facility.id);

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPage(facility: facility),
          ),
        );

        await _loadFavorites();
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar fasilitas
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: facility.image != null &&
                  facility.image!.isNotEmpty
                  ? Image.network(
                facility.image!,
                width: 85,
                height: 105,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _imagePlaceholder(),
              )
                  : _imagePlaceholder(),
            ),

            const SizedBox(width: 12),

            // Informasi fasilitas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    facility.category,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    facility.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 7),

                  // Rating dan ulasan
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${facility.rating} (${facility.reviewCount} ulasan)',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Status buka atau tutup
                  Row(
                    children: [
                      Icon(
                        facility.isCurrentlyOpen
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: facility.isCurrentlyOpen
                            ? Colors.green
                            : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        facility.isCurrentlyOpen ? 'Buka' : 'Tutup',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: facility.isCurrentlyOpen
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Jam operasional
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          facility.openingHours,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Jarak dari lokasi pengguna
                  if (distance != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me,
                          color: AppColors.primary,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          LocationService.formatDistance(distance),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Tombol favorit
            Column(
              children: [
                IconButton(
                  onPressed: () => _toggleFavorite(facility),
                  tooltip: isFavorite
                      ? 'Hapus dari Favorit'
                      : 'Tambahkan ke Favorit',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 22,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder jika gambar gagal dimuat
  Widget _imagePlaceholder() {
    return Container(
      width: 85,
      height: 105,
      color: Colors.blue.shade50,
      child: const Icon(
        Icons.local_hospital,
        color: AppColors.primary,
        size: 35,
      ),
    );
  }
}
