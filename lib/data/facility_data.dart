
import '../models/facility.dart';

class FacilityData {
  static const List<Facility> facilities = [
    // =========================
    // RUMAH SAKIT
    // =========================
    Facility(
      id: 'f001',
      name: 'RSUD Kabupaten X',
      category: 'Rumah Sakit',
      address: 'Jl. Raya Kabupaten X No. 10',
      latitude: -6.1754,
      longitude: 106.8272,
      image: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=600',
      rating: 4.5,
      reviewCount: 120,
      isOpen: true,
      openingHours: 'Buka 24 jam',
      services: ['IGD', 'Poliklinik', 'Rawat Inap', 'Laboratorium', 'Radiologi'],
      phone: '021-0000001',
      description: 'Rumah sakit umum dengan berbagai layanan kesehatan.',
    ),
    Facility(
      id: 'f002',
      name: 'RS Harapan Bunda',
      category: 'Rumah Sakit',
      address: 'Jl. Harapan No. 20, Kabupaten X',
      latitude: -6.1900,
      longitude: 106.8200,
      image: 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=600',
      rating: 4.8,
      reviewCount: 98,
      isOpen: true,
      openingHours: 'Buka 24 jam',
      services: ['IGD', 'Poliklinik', 'Rawat Inap', 'Radiologi'],
      phone: '021-0000002',
      description: 'Rumah sakit dengan layanan kesehatan umum.',
    ),
    Facility(
      id: 'f003',
      name: 'RS Mitra Sehat',
      category: 'Rumah Sakit',
      address: 'Jl. Kesehatan No. 25, Kabupaten X',
      latitude: -6.1640,
      longitude: 106.8390,
      image: 'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=600',
      rating: 4.6,
      reviewCount: 105,
      isOpen: true,
      openingHours: 'Buka 24 jam',
      services: ['IGD', 'Poliklinik', 'Rawat Inap', 'Laboratorium'],
      phone: '021-0000003',
      description: 'Rumah sakit dengan layanan pemeriksaan dan perawatan.',
    ),

    // =========================
    // PUSKESMAS
    // =========================
    Facility(
      id: 'f004',
      name: 'Puskesmas Sukamaju',
      category: 'Puskesmas',
      address: 'Jl. Sukamaju No. 5, Kabupaten X',
      latitude: -6.1800,
      longitude: 106.8350,
      image: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=600',
      rating: 4.3,
      reviewCount: 85,
      isOpen: true,
      openingHours: '08.00 - 14.00',
      services: ['Umum', 'KIA', 'Imunisasi', 'Laboratorium'],
      phone: '021-0000004',
      description: 'Pusat pelayanan kesehatan masyarakat.',
    ),
    Facility(
      id: 'f005',
      name: 'Puskesmas Melati',
      category: 'Puskesmas',
      address: 'Jl. Melati No. 12, Kabupaten X',
      latitude: -6.1700,
      longitude: 106.8150,
      image: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600',
      rating: 4.4,
      reviewCount: 72,
      isOpen: true,
      openingHours: '08.00 - 14.00',
      services: ['Umum', 'KIA', 'Imunisasi', 'Konsultasi'],
      phone: '021-0000005',
      description: 'Pelayanan kesehatan dasar bagi masyarakat.',
    ),
    Facility(
      id: 'f006',
      name: 'Puskesmas Sejahtera',
      category: 'Puskesmas',
      address: 'Jl. Sejahtera No. 8, Kabupaten X',
      latitude: -6.1950,
      longitude: 106.8420,
      image: 'https://images.unsplash.com/photo-1584982751601-97dcc096659c?w=600',
      rating: 4.2,
      reviewCount: 61,
      isOpen: true,
      openingHours: '08.00 - 14.00',
      services: ['Umum', 'KIA', 'Imunisasi', 'Kesehatan Gigi'],
      phone: '021-0000006',
      description: 'Puskesmas untuk pemeriksaan dan pelayanan kesehatan dasar.',
    ),

    // =========================
    // KLINIK
    // =========================
    Facility(
      id: 'f007',
      name: 'Klinik Sehat Mandiri',
      category: 'Klinik',
      address: 'Jl. Merdeka No. 15, Kabupaten X',
      latitude: -6.1680,
      longitude: 106.8400,
      image: 'https://images.unsplash.com/photo-1624727828489-a1e03b79bba8?w=600',
      rating: 4.2,
      reviewCount: 64,
      isOpen: true,
      openingHours: '08.00 - 21.00',
      services: ['Umum', 'Gigi', 'Laboratorium'],
      phone: '021-0000007',
      description: 'Klinik kesehatan untuk pemeriksaan umum dan gigi.',
    ),
    Facility(
      id: 'f008',
      name: 'Klinik Pratama Medika',
      category: 'Klinik',
      address: 'Jl. Medika No. 7, Kabupaten X',
      latitude: -6.1850,
      longitude: 106.8100,
      image: 'https://images.unsplash.com/photo-1551076805-e1869033e561?w=600',
      rating: 4.5,
      reviewCount: 89,
      isOpen: true,
      openingHours: '08.00 - 20.00',
      services: ['Umum', 'Gigi', 'Konsultasi Dokter'],
      phone: '021-0000008',
      description: 'Klinik pratama untuk pemeriksaan kesehatan.',
    ),
    Facility(
      id: 'f009',
      name: 'Klinik Keluarga',
      category: 'Klinik',
      address: 'Jl. Keluarga No. 18, Kabupaten X',
      latitude: -6.1600,
      longitude: 106.8200,
      image: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600',
      rating: 4.6,
      reviewCount: 76,
      isOpen: true,
      openingHours: '09.00 - 21.00',
      services: ['Umum', 'KIA', 'Konsultasi Dokter'],
      phone: '021-0000009',
      description: 'Klinik keluarga untuk layanan kesehatan umum.',
    ),
  ];

  static List<Facility> search(String keyword) {
    final query = keyword.toLowerCase().trim();

    if (query.isEmpty) return facilities;

    return facilities.where((facility) {
      return facility.name.toLowerCase().contains(query) ||
          facility.category.toLowerCase().contains(query) ||
          facility.address.toLowerCase().contains(query);
    }).toList();
  }

  static List<Facility> filterByCategory(String category) {
    if (category == 'Semua') return facilities;

    return facilities
        .where((facility) => facility.category == category)
        .toList();
  }

  static Facility? findById(String id) {
    for (final facility in facilities) {
      if (facility.id == id) return facility;
    }

    return null;
  }
}
