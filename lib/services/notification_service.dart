
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'smart_village_channel',
    'Smart Village Notifications',
    description: 'Notifikasi informasi fasilitas kesehatan.',
    importance: Importance.max,
  );

  // Inisialisasi layanan notifikasi
  static Future<void> initialize() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
  }

  // Meminta izin notifikasi Android 13 ke atas
  static Future<bool> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final result =
    await androidPlugin?.requestNotificationsPermission();

    return result ?? false;
  }

  // Menampilkan notifikasi
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'smart_village_channel',
      'Smart Village Notifications',
      channelDescription:
      'Notifikasi informasi fasilitas kesehatan.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  // Contoh notifikasi untuk pengujian
  static Future<void> showTestNotification() async {
    await showNotification(
      id: 1,
      title: 'Smart Village',
      body: 'Notifikasi berhasil diaktifkan!',
    );
  }
}
