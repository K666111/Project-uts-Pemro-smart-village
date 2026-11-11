import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _openRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const SizedBox(height: 22),

                    // LOGO SMART VILLAGE
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.add_location_alt_rounded,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // JUDUL
                    const Text(
                      'Sehat Bersama\nSmart Village',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF173F78),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // DESKRIPSI
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'Temukan lokasi klinik, puskesmas, dan rumah sakit terdekat dengan mudah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7B8794),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ILUSTRASI DESA
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.42,
                      child: Image.asset(
                        'assets/images/welcome_village.jpg',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('GAGAL MEMUAT GAMBAR: $error');

                          return const Center(
                            child: Icon(
                              Icons.landscape_rounded,
                              size: 120,
                              color: Color(0xFF7CB9E8),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // TOMBOL MULAI
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _openRegister(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0875E8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Mulai',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // TOMBOL MASUK
                    TextButton(
                      onPressed: () => _openLogin(context),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
