
import 'package:flutter/material.dart';

import '../data/facility_data.dart';
import '../models/facility.dart';
import '../services/favorite_service.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';
import 'detail_page.dart';

class FacilityPage extends StatefulWidget {
  const FacilityPage({super.key});

  @override
  State<FacilityPage> createState() => _FacilityPageState();
}

class _FacilityPageState extends State<FacilityPage> {
  final TextEditingController searchController =
  TextEditingController();

  String selectedCategory = 'Semua';

  bool isLoadingLocation = false;
  bool locationReady = false;
  String? locationError;

  final Map<String, double> facilityDistances = {};
  final Set<String> favoriteIds = {};

  final List<String> categories = [
    'Semua',
    'Rumah Sakit',
    'Puskesmas',
    'Klinik',
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

  Future<void> _openDetail(Facility facility) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(facility: facility),
      ),
    );

    await _loadFavorites();
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
        title: const Text(
          'Fasilitas Kesehatan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama atau alamat fasilitas...',
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
          ),

          // Status GPS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _locationStatus(),
          ),

          const SizedBox(height: 12),

          // Filter kategori
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) =>
              const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Jumlah fasilitas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Daftar Fasilitas',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${facilities.length} fasilitas',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Daftar fasilitas
          Expanded(
            child: facilities.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 55,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Fasilitas tidak ditemukan.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              itemCount: facilities.length,
              itemBuilder: (context, index) {
                return _facilityCard(facilities[index]);
              },
            ),
          ),
        ],
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
      'Lokasi berhasil ditemukan. Daftar diurutkan dari yang terdekat.';
      icon = Icons.my_location;
      color = Colors.green;
    } else {
      message = locationError ?? 'Lokasi belum tersedia.';
      icon = Icons.location_off;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 10,
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

  // Kartu fasilitas
  Widget _facilityCard(Facility facility) {
    final distance = facilityDistances[facility.id];
    final isFavorite = favoriteIds.contains(facility.id);

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => _openDetail(facility),
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
            // Foto fasilitas
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: facility.image != null &&
                  facility.image!.isNotEmpty
                  ? Image.network(
                facility.image!,
                width: 90,
                height: 110,
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    facility.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    facility.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${facility.rating} (${facility.reviewCount} ulasan)',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Status operasional
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

                  const SizedBox(height: 5),

                  // Jam operasional
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.grey,
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
                          size: 13,
                          color: AppColors.primary,
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

            // Tombol favorit dan detail
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

  // Gambar pengganti
  Widget _imagePlaceholder() {
    return Container(
      width: 90,
      height: 110,
      color: Colors.blue.shade50,
      child: const Icon(
        Icons.local_hospital,
        color: AppColors.primary,
        size: 35,
      ),
    );
  }
}
