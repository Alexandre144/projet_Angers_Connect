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
    print('DEBUG FavService: addFavorite appelé pour category=$category');
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + category;
    final itemId = _getItemId(item);
    print('DEBUG FavService: itemId=$itemId');
    final Map<String, dynamic> favorites = await _loadFavorites(key);
    print('DEBUG FavService: favorites avant ajout: ${favorites.keys.length} items');
    favorites[itemId] = item;
    await prefs.setString(key, json.encode(favorites));
    print('DEBUG FavService: favorites après ajout: ${favorites.keys.length} items');
  }

  Future<void> removeFavorite(String category, Map<String, dynamic> item) async {
    print('DEBUG FavService: removeFavorite appelé pour category=$category');
    final prefs = await SharedPreferences.getInstance();
    final key = _keyPrefix + category;
    final itemId = _getItemId(item);
    print('DEBUG FavService: itemId=$itemId');
    final Map<String, dynamic> favorites = await _loadFavorites(key);
    print('DEBUG FavService: favorites avant suppression: ${favorites.keys.length} items');
    favorites.remove(itemId);
    await prefs.setString(key, json.encode(favorites));
    print('DEBUG FavService: favorites après suppression: ${favorites.keys.length} items');
  }

  Future<bool> isFavorite(String category, Map<String, dynamic> item) async {
    print('DEBUG FavService: isFavorite appelé pour category=$category');
    final key = _keyPrefix + category;
    final itemId = _getItemId(item);
    print('DEBUG FavService: itemId=$itemId');
    final Map<String, dynamic> favorites = await _loadFavorites(key);
    final result = favorites.containsKey(itemId);
    print('DEBUG FavService: isFavorite result=$result (${favorites.keys.length} items total)');
    return result;
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
        if (decoded is Map) {
          print('DEBUG FavService: Chargé nouveau format Map');
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      print('DEBUG FavService: getString a échoué, essai getStringList: $e');
    }

    try {
      final listData = prefs.getStringList(key);
      if (listData != null && listData.isNotEmpty) {
        print('DEBUG FavService: Migration ancien format List<String> vers Map');
        final Map<String, dynamic> migrated = {};
        for (final jsonStr in listData) {
          try {
            final decoded = json.decode(jsonStr);
            if (decoded is Map) {
              final item = Map<String, dynamic>.from(decoded);
              final itemId = _getItemId(item);
              migrated[itemId] = item;
            }
          } catch (e) {
            print('DEBUG FavService: Erreur migration item: $e');
          }
        }
        await prefs.remove(key);
        if (migrated.isNotEmpty) {
          await prefs.setString(key, json.encode(migrated));
        }
        print('DEBUG FavService: Migration terminée, ${migrated.length} items');
        return migrated;
      }
    } catch (e) {
      print('DEBUG FavService: getStringList a échoué: $e');
    }

    return {};
  }
}
