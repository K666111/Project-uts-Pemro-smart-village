import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  final String code;
  final String name;
  final String flag;
  final Locale locale;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
    required this.locale,
  });
}

class LanguageService {
  static const String _storageKey = 'smart_village_language';

  static const List<AppLanguage> languages = [
    AppLanguage(
      code: 'id',
      name: 'Bahasa Indonesia',
      flag: '🇮🇩',
      locale: Locale('id'),
    ),
    AppLanguage(
      code: 'en',
      name: 'English',
      flag: '🇬🇧',
      locale: Locale('en'),
    ),
    AppLanguage(
      code: 'ms',
      name: 'Bahasa Melayu',
      flag: '🇲🇾',
      locale: Locale('ms'),
    ),
    AppLanguage(
      code: 'zh',
      name: '中文 (Mandarin)',
      flag: '🇨🇳',
      locale: Locale('zh', 'CN'),
    ),
    AppLanguage(code: 'ja', name: '日本語', flag: '🇯🇵', locale: Locale('ja')),
    AppLanguage(code: 'ko', name: '한국어', flag: '🇰🇷', locale: Locale('ko')),
    AppLanguage(
      code: 'ar',
      name: 'العربية',
      flag: '🇸🇦',
      locale: Locale('ar'),
    ),
    AppLanguage(
      code: 'es',
      name: 'Español',
      flag: '🇪🇸',
      locale: Locale('es'),
    ),
    AppLanguage(
      code: 'fr',
      name: 'Français',
      flag: '🇫🇷',
      locale: Locale('fr'),
    ),
  ];

  static final ValueNotifier<String> languageCode = ValueNotifier<String>('id');

  static AppLanguage get currentLanguage {
    return languages.firstWhere(
      (language) => language.code == languageCode.value,
      orElse: () => languages.first,
    );
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_storageKey);

    final isSupported = languages.any((language) => language.code == savedCode);

    languageCode.value = isSupported ? savedCode! : 'id';
  }

  static Future<void> changeLanguage(String code) async {
    final isSupported = languages.any((language) => language.code == code);

    if (!isSupported) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, code);

    languageCode.value = code;
  }
}
