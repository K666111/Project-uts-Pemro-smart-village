import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/language_settings_tile.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final ImagePicker imagePicker = ImagePicker();

  String email = '';
  String? profileImagePath;

  bool isLoading = true;
  bool isSaving = false;
  bool isPickingImage = false;
  bool notificationsEnabled = false;
  bool isUpdatingNotification = false;

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool('notifications_enabled') ?? false;

    if (!mounted) return;

    setState(() {
      notificationsEnabled = enabled;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (isUpdatingNotification) return;

    setState(() {
      isUpdatingNotification = true;
    });

    try {
      if (value) {
        final permission = await NotificationService.requestPermission();

        if (!permission) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin notifikasi belum diberikan. '
                'Silakan periksa pengaturan perangkat.',
              ),
            ),
          );

          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notifications_enabled', value);

      if (!mounted) return;

      setState(() {
        notificationsEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Notifikasi berhasil diaktifkan.'
                : 'Notifikasi berhasil dinonaktifkan.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah pengaturan: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingNotification = false;
        });
      }
    }
  }

  Future<void> _sendTestNotification() async {
    if (!notificationsEnabled) return;

    try {
      await NotificationService.showTestNotification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifikasi percobaan telah dikirim.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim notifikasi: $error')),
      );
    }
  }

  String get _photoStorageKey {
    return 'profile_photo_${email.toLowerCase()}';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotificationSetting();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final name = await AuthService.currentUserName();
      final userEmail = await AuthService.currentUserEmail();
      final phone = await AuthService.currentUserPhone();

      final prefs = await SharedPreferences.getInstance();
      final savedPhoto = userEmail == null
          ? null
          : prefs.getString('profile_photo_${userEmail.toLowerCase()}');

      if (!mounted) return;

      String? validPhoto = savedPhoto;

      if (savedPhoto != null && !await File(savedPhoto).exists()) {
        validPhoto = null;

        if (userEmail != null) {
          await prefs.remove('profile_photo_${userEmail.toLowerCase()}');
        }
      }

      setState(() {
        nameController.text = name ?? '';
        email = userEmail ?? '';
        emailController.text = userEmail ?? '';
        phoneController.text = phone ?? '';
        profileImagePath = validPhoto;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat profil: $error')));
    }
  }

  // Memilih foto dari galeri
  Future<void> _pickProfileImage() async {
    if (isPickingImage) return;

    setState(() {
      isPickingImage = true;
    });

    try {
      final XFile? pickedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedImage == null) return;

      // Menyiapkan folder penyimpanan permanen aplikasi
      final directory = await getApplicationDocumentsDirectory();

      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}_'
          '${pickedImage.name.split('/').last.split(r'\').last}';

      final savedPath = '${directory.path}${Platform.pathSeparator}$fileName';

      // Menyalin foto ke penyimpanan aplikasi
      final savedImage = await File(pickedImage.path).copy(savedPath);

      // Menyimpan lokasi foto berdasarkan akun pengguna
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_photoStorageKey, savedImage.path);

      if (!mounted) return;

      setState(() {
        profileImagePath = savedImage.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengganti foto profil: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isPickingImage = false;
        });
      }
    }
  }

  // Menghapus foto profil
  Future<void> _removeProfileImage() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_photoStorageKey);

    if (!mounted) return;

    setState(() {
      profileImagePath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto profil berhasil dihapus.')),
    );
  }

  // Menu foto profil
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Foto Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickProfileImage();
                  },
                ),
                if (profileImagePath != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text('Hapus Foto Profil'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _removeProfileImage();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Batal'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Menyimpan perubahan profil
  Future<void> _saveProfile() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap tidak boleh kosong.')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final result = await AuthService.updateProfile(
        name: name,
        phone: phoneController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      if (result != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result)));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );

      await _loadProfile();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $error')));
    }
  }

  // Konfirmasi logout
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah kamu yakin ingin keluar dari akun?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      widget.onLogout();
    }
  }

  // Tampilan foto profil
  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: profileImagePath != null
                ? Image.file(
                    File(profileImagePath!),
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return _defaultAvatar();
                    },
                  )
                : _defaultAvatar(),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isPickingImage ? null : _showPhotoOptions,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: isPickingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    final name = nameController.text.trim();

    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 40,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil Pengguna',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Informasi pengguna
                Center(
                  child: Column(
                    children: [
                      _buildProfileAvatar(),

                      const SizedBox(height: 12),

                      Text(
                        nameController.text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        email,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 5),

                      TextButton.icon(
                        onPressed: _showPhotoOptions,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Ubah Foto Profil'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Informasi Akun',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 14),

                // Nama lengkap
                TextField(
                  controller: nameController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 14),

                // Email
                TextField(
                  controller: emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 14),

                // Nomor telepon
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    hintText: 'Masukkan nomor telepon',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 18),

                // Tombol simpan
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : _saveProfile,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const LanguageSettingsTile(),

                const SizedBox(height: 10),
                const Divider(),

                const SizedBox(height: 28),

                const Text(
                  'Pengaturan Notifikasi',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Notifikasi Smart Village',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    notificationsEnabled
                        ? 'Notifikasi sedang diaktifkan'
                        : 'Notifikasi sedang dinonaktifkan',
                  ),
                  value: notificationsEnabled,
                  onChanged: isUpdatingNotification
                      ? null
                      : _toggleNotifications,
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Kirim Notifikasi Percobaan'),
                  subtitle: const Text(
                    'Coba tampilkan notifikasi dari Smart Village',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: notificationsEnabled,
                  onTap: notificationsEnabled ? _sendTestNotification : null,
                ),

                const SizedBox(height: 10),
                const Divider(),

                // Tentang aplikasi
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                  ),
                  title: const Text('Tentang Smart Village'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Smart Village',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Aplikasi informasi fasilitas kesehatan.',
                    );
                  },
                ),

                // Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: _confirmLogout,
                ),
              ],
            ),
    );
  }
}
