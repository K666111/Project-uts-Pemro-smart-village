import 'package:flutter/material.dart';

import '../models/facility.dart';
import '../services/favorite_service.dart';
import '../services/location_service.dart';
import '../utils/app_colors.dart';
import 'map_page.dart';

class DetailPage extends StatefulWidget {
  final Facility facility;

  const DetailPage({super.key, required this.facility});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  double? distance;
  bool isLoadingDistance = true;
  String? distanceError;

  bool isFavorite = false;
  bool isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _loadDistance();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final result = await FavoriteService.isFavorite(widget.facility.id);

    if (!mounted) return;

    setState(() {
      isFavorite = result;
      isLoadingFavorite = false;
    });
  }

  Future<void> _toggleFavorite() async {
    await FavoriteService.toggleFavorite(widget.facility.id);

    if (!mounted) return;

    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? '${widget.facility.name} ditambahkan ke Favorit.'
              : '${widget.facility.name} dihapus dari Favorit.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadDistance() async {
    final facility = widget.facility;

    if (facility.latitude == null || facility.longitude == null) {
      if (!mounted) return;

      setState(() {
        isLoadingDistance = false;
        distanceError = 'Koordinat fasilitas belum tersedia.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        isLoadingDistance = true;
        distanceError = null;
      });
    }

    try {
      final position = await LocationService.getCurrentLocation();

      final result = LocationService.calculateDistance(
        userLatitude: position.latitude,
        userLongitude: position.longitude,
        facilityLatitude: facility.latitude!,
        facilityLongitude: facility.longitude!,
      );

      if (!mounted) return;

      setState(() {
        distance = result;
        isLoadingDistance = false;
        distanceError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingDistance = false;
        distanceError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Menentukan ikon berdasarkan nama layanan.
  IconData _getServiceIcon(String service) {
    final name = service.toLowerCase().trim();

    if (name.contains('igd') || name.contains('darurat')) {
      return Icons.emergency;
    }

    if (name.contains('poliklinik')) {
      return Icons.local_hospital;
    }

    if (name.contains('rawat inap')) {
      return Icons.bed;
    }

    if (name.contains('laboratorium')) {
      return Icons.biotech;
    }

    if (name.contains('radiologi')) {
      return Icons.monitor_heart;
    }

    if (name == 'kia' || name.contains('ibu dan anak')) {
      return Icons.child_care;
    }

    if (name.contains('imunisasi')) {
      return Icons.vaccines;
    }

    if (name.contains('gigi')) {
      return Icons.health_and_safety;
    }

    if (name.contains('konsultasi')) {
      return Icons.chat_bubble_outline;
    }

    if (name.contains('umum')) {
      return Icons.medical_services;
    }

    return Icons.health_and_safety;
  }

  // Menentukan warna ikon berdasarkan kategori fasilitas.
  Color _getServiceColor() {
    final category = widget.facility.category.toLowerCase();

    if (category.contains('rumah sakit')) {
      return const Color(0xFF2476C8);
    }

    if (category.contains('puskesmas')) {
      return const Color(0xFF16A085);
    }

    if (category.contains('klinik')) {
      return const Color(0xFF8E63CE);
    }

    return AppColors.primary;
  }

  // Tampilan satu ikon layanan.
  Widget _buildServiceItem(String service) {
    final color = _getServiceColor();

    return Container(
      width: 125,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(_getServiceIcon(service), color: color, size: 25),
          ),
          const SizedBox(height: 10),
          Text(
            service,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facility = widget.facility;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: isLoadingFavorite ? null : _toggleFavorite,
                tooltip: isFavorite
                    ? 'Hapus dari Favorit'
                    : 'Tambahkan ke Favorit',
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red.shade200 : Colors.white,
                  size: 25,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                facility.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: facility.image != null && facility.image!.isNotEmpty
                  ? Image.network(
                      facility.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return Container(
                          color: AppColors.primary,
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 80,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.primary,
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.category,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    facility.name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 21),
                      const SizedBox(width: 5),
                      Text(
                        '${facility.rating} (${facility.reviewCount} ulasan)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // STATUS OPERASIONAL
                  _buildInfoCard(
                    icon: Icons.access_time,
                    title: 'Status Operasional',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facility.isCurrentlyOpen ? 'Buka' : 'Tutup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: facility.isCurrentlyOpen
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text('Jam operasional: ${facility.openingHours}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // JARAK
                  _buildInfoCard(
                    icon: Icons.route,
                    title: 'Jarak dari Lokasi Anda',
                    child: Row(
                      children: [
                        Expanded(
                          child: isLoadingDistance
                              ? const Text('Menghitung jarak...')
                              : distance != null
                              ? Text(
                                  LocationService.formatDistance(distance!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : Text(
                                  distanceError ?? 'Jarak belum tersedia',
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                  ),
                                ),
                        ),
                        IconButton(
                          onPressed: _loadDistance,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Hitung ulang jarak',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ALAMAT
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Alamat',
                    child: Text(facility.address),
                  ),

                  const SizedBox(height: 12),

                  // LAYANAN KESEHATAN DENGAN IKON
                  _buildInfoCard(
                    icon: Icons.medical_services,
                    title: 'Layanan Kesehatan',
                    child: facility.services.isEmpty
                        ? const Text('Belum ada informasi layanan.')
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: facility.services.map((service) {
                              return _buildServiceItem(service);
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // TENTANG FASILITAS
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    title: 'Tentang Fasilitas',
                    child: Text(
                      facility.description ?? 'Informasi fasilitas kesehatan.',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // NOMOR TELEPON
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'Nomor Telepon',
                    child: Text(
                      facility.phone ?? 'Nomor telepon belum tersedia.',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TOMBOL LIHAT PETA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapPage(selectedFacility: facility),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Lihat di Peta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
