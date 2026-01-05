import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/tram_arret.dart';

class TramArretRepository {
  final String baseUrl = "https://data.angers.fr/api/explore/v2.1/catalog/datasets/horaires-theoriques-et-arrets-du-reseau-irigo-gtfs/records?limit=100";

  Future<List<TramArret>> fetchTramArrets() async {
    // Charger le mapping stop_id -> Set<route_short_name> depuis le fichier TXT
    // Correction : stop_id -> Set<route_short_name>
    final Map<String, Set<String>> stopIdToRouteShortNames = {};
    try {
      final rawTxt = await rootBundle.loadString('assets/data/arrets_lignes_irigo.txt');
      final lines = rawTxt.split('\n');
      print('DEBUG: Fichier TXT chargé via rootBundle, ${lines.length} lignes.');
      bool foundPigeo2 = false;
      for (final l in lines.skip(1)) { // skip header
        if (!foundPigeo2 && l.contains('PIGEO2-E')) {
          print('DEBUG: Ligne PIGEO2-E : $l');
          foundPigeo2 = true;
        }
        final parts = l.split(';');
        if (parts.length < 4) continue;
        final stopId = parts[1].trim().toUpperCase();
        final routeShortName = parts[3];
        stopIdToRouteShortNames.putIfAbsent(stopId, () => <String>{}).add(routeShortName);
      }
      print('DEBUG: Taille totale du mapping = ${stopIdToRouteShortNames.length}');
      print('DEBUG: --- Début recherche clés PIGEO2/HERISS ---');
      final pigKeys = stopIdToRouteShortNames.keys.where((k) => k.contains('PIGEO2')).toList();
      final herissKeys = stopIdToRouteShortNames.keys.where((k) => k.contains('HERISS')).toList();
      print('DEBUG: Clés du mapping contenant "PIGEO2" :');
      for (final k in pigKeys) {
        print('  "$k" (longueur: ${k.length})');
      }
      print('DEBUG: Clés du mapping contenant "HERISS" :');
      for (final k in herissKeys) {
        print('  "$k" (longueur: ${k.length})');
      }
      print('DEBUG: --- Fin recherche clés PIGEO2/HERISS ---');
    } catch (e) {
      print('DEBUG: Erreur chargement TXT via rootBundle : $e');
    }
    int start = 0;
    int totalCount = 0;
    final int limit = 100;
    List<TramArret> allArrets = [];
    bool firstRequest = true;
    int linkedCount = 0;
    int unlinkedCount = 0;

    do {
      final url = baseUrl + "&offset=$start";
      final Response response = await get(Uri.parse(url));
      print('DEBUG: API statusCode = \\${response.statusCode}');
      if (response.statusCode != 200) {
        throw Exception('Failed to load tram stops (status: \\u001b[31m\\${response.statusCode}\\u001b[0m)');
      }
      print('DEBUG: API body (début) = \\${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      if (firstRequest) {
        totalCount = jsonResponse['total_count'] is int ? jsonResponse['total_count'] : int.tryParse(jsonResponse['total_count']?.toString() ?? '') ?? 0;
        firstRequest = false;
      }
      final results = jsonResponse['results'];
      print('DEBUG: Taille de results = \\${results is List ? results.length : 'non-list'}');
      if (results is List) {
        allArrets.addAll(results.map((item) {
          final stopIdRaw = (item as Map<String, dynamic>)['stop_id']?.toString() ?? '';
          final stopId = stopIdRaw.trim().toUpperCase();
          final routeShortNames = stopIdToRouteShortNames[stopId] ?? {};
          if (!routeShortNames.isNotEmpty && (stopId == 'PIGEO2-E' || stopId == 'HERISS-E')) {
            final similar = stopIdToRouteShortNames.keys.where((k) => k.contains(stopId.substring(0, 4))).toList();
            print('DEBUG: Pas de lignes pour stop_id "$stopIdRaw". Similaires: $similar');
          }
          return TramArret.fromJson(item, routeShortNames);
        }));
      } else {
        break;
      }
      start += limit;
    } while (allArrets.length < totalCount && totalCount > 0);
    print('TramArretRepository : $linkedCount arrêts liés à une ligne, $unlinkedCount arrêts non liés');
    return allArrets;
  }
}