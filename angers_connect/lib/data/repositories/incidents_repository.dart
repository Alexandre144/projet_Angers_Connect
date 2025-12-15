import '../models/incident_model.dart';

class IncidentsRepository {
  final List<Incident> _incidents = [];

  IncidentsRepository([List<Incident>? initial]) {
    if (initial != null) _incidents.addAll(initial);
  }

  Future<List<Incident>> getIncidents({bool forceRefresh = false}) async {
    return List<Incident>.from(_incidents);
  }

  void setIncidents(List<Incident> incidents) {
    _incidents.clear();
    _incidents.addAll(incidents);
  }
}
