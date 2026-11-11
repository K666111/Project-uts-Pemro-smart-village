
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class InfoPage extends StatelessWidget {
  final VoidCallback onLogout;

  const InfoPage({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Smart Village'),
        backgroundColor: AppColors.background,
      ),
      body: FutureBuilder<String?>(
        future: AuthService.currentUserName(),
        builder: (context, snapshot) {
          final name = snapshot.data ?? 'Pengguna';

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_city,
                  size: 65,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),

                const Text(
                  'SMART VILLAGE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Smart Village merupakan aplikasi '
                      'pencarian fasilitas kesehatan yang '
                      'memanfaatkan teknologi lokasi untuk '
                      'membantu masyarakat menemukan fasilitas '
                      'kesehatan di sekitarnya.',
                ),

                const SizedBox(height: 30),

                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text('Nama pengguna: $name'),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
