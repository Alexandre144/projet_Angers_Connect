import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/incident_model.dart';

class IncidentsRepository {
  final List<Incident> _incidents = [];
  final String baseUrl;

  IncidentsRepository([List<Incident>? initial, String? baseUrl])
      : baseUrl = baseUrl ?? 'https://data.angers.fr/api/records/1.0/search/?dataset=info-travaux&rows=200' {
    if (initial != null) _incidents.addAll(initial);
  }

  Future<List<Incident>> getIncidents({bool forceRefresh = false, String? q}) async {
    if (_incidents.isNotEmpty && !forceRefresh) {
      return List<Incident>.from(_incidents);
    }

    final uri = Uri.parse(baseUrl);
    final uriWithQuery = (q == null || q.trim().isEmpty)
        ? uri
        : uri.replace(queryParameters: {...uri.queryParameters, 'q': q});

    final response = await http.get(uriWithQuery, headers: {'Accept': 'application/json'});
    if (response.statusCode != 200) {
      throw Exception('Failed to load incidents (status ${response.statusCode})');
    }

    final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
    final records = data['records'] as List<dynamic>?;
    final List<Incident> result = [];
    if (records != null) {
      for (final rec in records) {
        if (rec is Map<String, dynamic>) {
          try {
            result.add(Incident.fromJson(rec));
          } catch (_) {
            // ignorer les enregistrements mal formés
          }
        } else if (rec is Map) {
          result.add(Incident.fromJson(Map<String, dynamic>.from(rec)));
        }
      }
    }

    _incidents.clear();
    _incidents.addAll(result);

    return result;
  }

  void setIncidents(List<Incident> incidents) {
    _incidents.clear();
    _incidents.addAll(incidents);
  }
}
