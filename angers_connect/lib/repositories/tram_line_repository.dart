import 'dart:convert';
import 'package:http/http.dart';
import '../models/tram_line.dart';

class TramLineRepository {
  final String baseUrl = "https://data.angers.fr/api/records/1.0/search/?dataset=irigo_gtfs_lines&rows=100";

  Future<List<TramLine>> fetchTramLines() async {
    int start = 0;
    int totalHits = 0;
    final int rows = 100;
    List<TramLine> allTramLines = [];
    bool firstRequest = true;

    do {
      final url = baseUrl + '&start=$start';
      final Response response = await get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load tram lines (status: \\${response.statusCode})');
      }
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      if (firstRequest) {
        totalHits = jsonResponse['nhits'] is int ? jsonResponse['nhits'] : int.tryParse(jsonResponse['nhits']?.toString() ?? '') ?? 0;
        firstRequest = false;
      }
      final records = jsonResponse['records'];
      if (records is List) {
        allTramLines.addAll(records.map((item) => TramLine.fromJson(item as Map<String, dynamic>)));
      } else {
        break; // format inattendu, on arrête
      }
      start += rows;
    } while (allTramLines.length < totalHits && totalHits > 0);
    return allTramLines;
  }
}