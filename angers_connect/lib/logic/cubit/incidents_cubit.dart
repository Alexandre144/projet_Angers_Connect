import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/incidents_repository.dart';
import '../../data/models/incident_model.dart';

class IncidentsCubit extends Cubit<List<Incident>> {
  final IncidentsRepository repository;

  IncidentsCubit(this.repository) : super(const []);

  Future<void> load() async {
    try {
      final list = await repository.getIncidents();
      emit(list);
    } catch (_) {
      emit(const []);
    }
  }
}

