import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/tram_arret.dart';
import '../repositories/tram_arret_repository.dart';

class TramArretCubit extends Cubit<List<TramArret>> {
  final TramArretRepository _repository;

  TramArretCubit(this._repository) : super([]) {
    fetchTramLines();
  }

  Future<void> fetchTramLines() async {
    try {
      final tramLines = await _repository.fetchTramArrets();
      emit(tramLines);
    } catch (e) {
      emit([]);
    }
  }
}