
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _accountsKey = 'smart_village_accounts';
  static const String _sessionNameKey = 'session_name';
  static const String _sessionEmailKey = 'session_email';

  static String _phoneKey(String email) =>
      'profile_phone_${email.trim().toLowerCase()}';

  static String _generateSalt() {
    final random = Random.secure();

    return List.generate(
      16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  static Future<List<Map<String, dynamic>>> _getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_accountsKey);

    if (data == null) return [];

    final decoded = jsonDecode(data) as List;

    return decoded
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _getAccounts();

    final normalizedEmail = email.trim().toLowerCase();

    final exists = accounts.any(
          (account) => account['email'] == normalizedEmail,
    );

    if (exists) {
      return 'Email sudah terdaftar.';
    }

    final salt = _generateSalt();

    accounts.add({
      'name': name.trim(),
      'email': normalizedEmail,
      'salt': salt,
      'passwordHash': _hashPassword(password, salt),
    });

    await prefs.setString(_accountsKey, jsonEncode(accounts));
    await prefs.setString(_sessionNameKey, name.trim());
    await prefs.setString(_sessionEmailKey, normalizedEmail);

    return null;
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _getAccounts();

    final normalizedEmail = email.trim().toLowerCase();

    for (final account in accounts) {
      if (account['email'] == normalizedEmail) {
        final salt = account['salt'] as String;
        final passwordHash = _hashPassword(password, salt);

        if (passwordHash == account['passwordHash']) {
          await prefs.setString(
            _sessionNameKey,
            account['name'] as String,
          );

          await prefs.setString(
            _sessionEmailKey,
            normalizedEmail,
          );

          return null;
        }

        return 'Password yang kamu masukkan salah.';
      }
    }

    return 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.';
  }

  static Future<String?> currentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionNameKey);
  }

  static Future<String?> currentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionEmailKey);
  }

  static Future<String?> currentUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionEmailKey);

    if (email == null) return null;

    return prefs.getString(_phoneKey(email));
  }

  static Future<String?> updateProfile({
    required String name,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final email = prefs.getString(_sessionEmailKey);

    if (email == null) {
      return 'Sesi pengguna tidak ditemukan.';
    }

    if (name.trim().isEmpty) {
      return 'Nama tidak boleh kosong.';
    }

    final accounts = await _getAccounts();

    final accountIndex = accounts.indexWhere(
          (account) => account['email'] == email,
    );

    if (accountIndex == -1) {
      return 'Data akun tidak ditemukan.';
    }

    accounts[accountIndex]['name'] = name.trim();

    await prefs.setString(
      _accountsKey,
      jsonEncode(accounts),
    );

    await prefs.setString(
      _sessionNameKey,
      name.trim(),
    );

    await prefs.setString(
      _phoneKey(email),
      phone.trim(),
    );

    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_sessionNameKey);
    await prefs.remove(_sessionEmailKey);
  }
}
