import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/tram_line.dart';
import '../repositories/tram_line_repository.dart';

class TramLineCubit extends Cubit<List<TramLine>> {
  final TramLineRepository _repository;

  TramLineCubit(this._repository) : super([]) {
    fetchTramLines();
  }

  Future<void> fetchTramLines() async {
    try {
      final tramLines = await _repository.fetchTramLines();
      emit(tramLines);
    } catch (e) {
      emit([]);
    }
  }
}