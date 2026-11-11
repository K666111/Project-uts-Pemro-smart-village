
class Facility {
  final String id;
  final String name;
  final String category;
  final String address;

  final double? latitude;
  final double? longitude;
  final String? image;

  final double rating;
  final int reviewCount;

  // Nilai ini tetap disimpan untuk kompatibilitas data lama.
  final bool isOpen;

  final String openingHours;
  final List<String> services;

  final String? phone;
  final String? description;

  const Facility({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.latitude,
    this.longitude,
    this.image,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOpen = true,
    this.openingHours = '08.00 - 21.00',
    this.services = const [],
    this.phone,
    this.description,
  });

  // Menghitung status buka/tutup berdasarkan jam operasional.
  bool get isCurrentlyOpen {
    final hours = openingHours.toLowerCase().trim();

    // Fasilitas yang beroperasi 24 jam.
    if (hours.contains('24 jam') || hours.contains('24 hours')) {
      return true;
    }

    // Memisahkan jam mulai dan jam selesai.
    final parts = hours.split('-');

    if (parts.length != 2) {
      return false;
    }

    final start = _parseTime(parts[0]);
    final end = _parseTime(parts[1]);

    if (start == null || end == null) {
      return false;
    }

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // Jam operasional normal, misalnya 08.00 - 21.00.
    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes &&
          currentMinutes < endMinutes;
    }

    // Jam operasional melewati tengah malam,
    // misalnya 20.00 - 06.00.
    if (startMinutes > endMinutes) {
      return currentMinutes >= startMinutes ||
          currentMinutes < endMinutes;
    }

    // Jam mulai dan selesai sama dianggap tutup.
    return false;
  }

  // Mengubah teks jam menjadi jam dan menit.
  static _ParsedTime? _parseTime(String value) {
    final normalized = value.trim().replaceAll('.', ':');
    final parts = normalized.split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return _ParsedTime(hour, minute);
  }
}

class _ParsedTime {
  final int hour;
  final int minute;

  const _ParsedTime(this.hour, this.minute);
}
