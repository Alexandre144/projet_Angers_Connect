import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _keyPrefix = 'favorites_';

  String _getItemId(Map<String, dynamic> item) {
    if (item.containsKey('id')) return 'id_${item['id']}';
    final name = item['nom'] ?? item['nom_parkng'] ?? item['title'] ?? '';
    final lat = item['lat']?.toString() ?? '';
    final lon = item['lon']?.toString() ?? '';
    return '${name}_${lat}_$lon';
  }

  Future<void> addFavorite(String category, Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + category;
    final itemId = _getItemId(item);
    final Map<String, dynamic> favorites = await _loadFavorites(key);
    favorites[itemId] = item;
    await prefs.setString(key, json.encode(favorites));
  }

  Future<void> removeFavorite(String category, Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + category;
    final itemId = _getItemId(item);
    final Map<String, dynamic> favorites = await _loadFavorites(key);
    favorites.remove(itemId);
    await prefs.setString(key, json.encode(favorites));
  }

  Future<bool> isFavorite(String category, Map<String, dynamic> item) async {
    final key = _keyPrefix + category;
    final itemId = _getItemId(item);
    final Map<String, dynamic> favorites = await _loadFavorites(key);
    return favorites.containsKey(itemId);
  }

  Future<List<Map<String, dynamic>>> getFavorites(String category) async {
    final key = _keyPrefix + category;
    final Map<String, dynamic> favorites = await _loadFavorites(key);
    return favorites.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> _loadFavorites(String key) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final stored = prefs.getString(key);
      if (stored != null && stored.isNotEmpty) {
        final decoded = json.decode(stored);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    try {
      final listData = prefs.getStringList(key);
      if (listData != null && listData.isNotEmpty) {
        final Map<String, dynamic> migrated = {};
        for (final jsonStr in listData) {
          try {
            final decoded = json.decode(jsonStr);
            if (decoded is Map) {
              final item = Map<String, dynamic>.from(decoded);
              final itemId = _getItemId(item);
              migrated[itemId] = item;
            }
          } catch (_) {}
        }
        await prefs.remove(key);
        if (migrated.isNotEmpty) {
          await prefs.setString(key, json.encode(migrated));
        }
        return migrated;
      }
    } catch (_) {}

    return {};
  }
}
