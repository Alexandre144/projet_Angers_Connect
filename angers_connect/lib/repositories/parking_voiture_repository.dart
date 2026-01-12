import 'dart:convert';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import '../models/parking_voiture.dart';

class ParkingVoitureRepository {
  final String baseUrl = "https://data.angers.fr/api/explore/v2.1/catalog/datasets/parking-angers/records?limit=100";

  static const Map<String, LatLng> _coords = {
    "Ralliement": LatLng(47.47372, -0.5523),
    "Republique": LatLng(47.4731, -0.5541),
    "Moliere": LatLng(47.47287, -0.54845),
    "Bressigny": LatLng(47.47543, -0.56078),
    "Berges De Maine": LatLng(47.47528, -0.52427),
    "Marengo": LatLng(47.46852, -0.5468),
    "Larrey": LatLng(47.47219, -0.55249),
    "Confluences": LatLng(47.47353, -0.54396),
    "Saint Serge Patinoire": LatLng(47.47961, -0.53645),
    "Mitterrand Maine": LatLng(47.4789, -0.5541),
    "Mail": LatLng(47.4715, -0.5527),
    "Saint Laud": LatLng(47.4671, -0.5453),
    "Haras Public": LatLng(47.47622, -0.55247),
    "Maternite": LatLng(47.4724, -0.5526),
    "Leclerc": LatLng(47.47191, -0.5533),
    "Mitterrand Rennes": LatLng(47.47865, -0.5555),
    "Saint Laud 2": LatLng(47.4674, -0.5445),
    "Quai": LatLng(47.4739, -0.5435),
  };

  Future<List<ParkingVoiture>> fetchParkingVoitures() async {
    int offset = 0;
    int totalCount = 0;
    final int limit = 100;
    List<ParkingVoiture> allParkings = [];
    bool firstRequest = true;

    do {
      final url = '$baseUrl&offset=$offset';
      final Response response = await get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load parking voitures (status: [${response.statusCode})');
      }
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      if (firstRequest) {
        totalCount = jsonResponse['total_count'] is int ? jsonResponse['total_count'] : int.tryParse(jsonResponse['total_count']?.toString() ?? '') ?? 0;
        firstRequest = false;
      }
      final results = jsonResponse['results'];
      if (results is List) {
        for (final item in results) {
          final nom = item['nom'] as String? ?? '';
          final disponible = (item['disponible'] ?? '').toString();
          final coords = _coords[nom];
          if (coords != null) {
            allParkings.add(ParkingVoiture(nom, disponible, coords));
          }
        }
      } else {
        break; // format inattendu, on arrête
      }
      offset += limit;
    } while (allParkings.length < totalCount && totalCount > 0);
    return allParkings;
  }
}