import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/parking_velo.dart';
import '../repositories/parking_velo_repository.dart';

class ParkingVeloCubit extends Cubit<List<ParkingVelo>> {
  final ParkingVeloRepository _repository;

  ParkingVeloCubit(this._repository) : super([]) {
    fetchParkings();
  }

  Future<void> fetchParkings() async {
    try {
      final parkings = await _repository.fetchParkingVelos();
      emit(parkings);
    } catch (e) {
      emit([]);
    }
  }
}
