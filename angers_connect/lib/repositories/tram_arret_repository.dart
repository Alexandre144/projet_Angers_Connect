import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tram_arret.dart';

class TramArretRepository {
  final String baseUrl = "https://data.angers.fr/api/explore/v2.1/catalog/datasets/horaires-theoriques-et-arrets-du-reseau-irigo-gtfs/records?limit=100";

  Future<List<TramArret>> fetchTramArrets() async {
    final Map<String, Set<String>> stopIdToRouteShortNames = {};
    try {
      final rawTxt = await rootBundle.loadString('assets/data/arrets_lignes_irigo.txt');
      final lines = rawTxt.split('\n');
      for (final l in lines.skip(1)) {
        final parts = l.split(';');
        if (parts.length < 4) continue;
        final stopId = parts[1].trim().toUpperCase();
        final routeShortName = parts[3];
        stopIdToRouteShortNames.putIfAbsent(stopId, () => <String>{}).add(routeShortName);
      }
    } catch (e) {
      // Silently ignore if file not found or can't be loaded
    }
    int start = 0;
    int totalCount = 0;
    final int limit = 100;
    List<TramArret> allArrets = [];
    bool firstRequest = true;

    do {
      final url = '$baseUrl&offset=$start';
      final Response response = await get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load tram stops (status: ${response.statusCode})');
      }
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      if (firstRequest) {
        totalCount = jsonResponse['total_count'] is int ? jsonResponse['total_count'] : int.tryParse(jsonResponse['total_count']?.toString() ?? '') ?? 0;
        firstRequest = false;
      }
      final results = jsonResponse['results'];
      if (results is List) {
        allArrets.addAll(results.map((item) {
          final stopIdRaw = (item as Map<String, dynamic>)['stop_id']?.toString() ?? '';
          final stopId = stopIdRaw.trim().toUpperCase();
          final routeShortNames = stopIdToRouteShortNames[stopId] ?? {};
          return TramArret.fromJson(item, routeShortNames);
        }));
      } else {
        break;
      }
      start += limit;
    } while (allArrets.length < totalCount && totalCount > 0);
    return allArrets;
  }
}