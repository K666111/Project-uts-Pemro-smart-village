
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _favoritesKey = 'smart_village_favorites';

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_favoritesKey);

    if (data == null) return [];

    try {
      final decoded = jsonDecode(data) as List;
      return decoded.map((item) => item.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isFavorite(String facilityId) async {
    final favorites = await getFavorites();
    return favorites.contains(facilityId);
  }

  static Future<void> toggleFavorite(String facilityId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    if (favorites.contains(facilityId)) {
      favorites.remove(facilityId);
    } else {
      favorites.add(facilityId);
    }

    await prefs.setString(
      _favoritesKey,
      jsonEncode(favorites),
    );
  }
}
