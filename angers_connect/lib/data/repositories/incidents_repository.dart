import '../models/incident_model.dart';

abstract class IncidentsRepository {
  Future<List<Incident>> getIncidents({bool forceRefresh = false});
}

class MemoryIncidentsRepository implements IncidentsRepository {
  final List<Incident> _incidents;

  MemoryIncidentsRepository([List<Incident>? initial]) : _incidents = initial ?? [];

  @override
  Future<List<Incident>> getIncidents({bool forceRefresh = false}) async {
    return List<Incident>.from(_incidents);
  }

  void setIncidents(List<Incident> incidents) {
    _incidents
      ..clear()
      ..addAll(incidents);
  }
}

