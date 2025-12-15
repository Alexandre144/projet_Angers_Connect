import 'dart:convert';
import 'package:http/http.dart';
import '../models/parking_velo.dart';

class ParkingVeloRepository {
  final String baseUrl = "https://data.angers.fr/api/explore/v2.1/catalog/datasets/parking-velo-angers/records?limit=100&select=nom_parkng,capacite,acces,date_maj,geo_point_2d";

  Future<List<ParkingVelo>> fetchParkingVelos() async {
    int offset = 0;
    int totalCount = 0;
    final int limit = 100;
    List<ParkingVelo> allParkings = [];
    bool firstRequest = true;

    do {
      final url = baseUrl + '&offset=$offset';
      final Response response = await get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load parking velos (status: ${response.statusCode})');
      }
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      if (firstRequest) {
        totalCount = jsonResponse['total_count'] is int ? jsonResponse['total_count'] : int.tryParse(jsonResponse['total_count']?.toString() ?? '') ?? 0;
        firstRequest = false;
      }
      final results = jsonResponse['results'];
      if (results is List) {
        allParkings.addAll(results.map((item) => ParkingVelo.fromJson(item as Map<String, dynamic>)));
      } else {
        break; // format inattendu, on arrête
      }
      offset += limit;
    } while (allParkings.length < totalCount && totalCount > 0);
    return allParkings;
  }
}