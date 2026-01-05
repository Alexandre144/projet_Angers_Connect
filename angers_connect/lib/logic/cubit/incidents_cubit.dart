import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/incidents_repository.dart';
import '../../data/models/incident_model.dart';

class IncidentsCubit extends Cubit<List<Incident>> {
  final IncidentsRepository repository;

  IncidentsCubit(this.repository) : super(const []);

  Future<void> load({String? q}) async {
    try {
      final list = await repository.getIncidents(q: q, forceRefresh: true);
      emit(list);
    } catch (_) {
      emit(const []);
    }
  }
}
