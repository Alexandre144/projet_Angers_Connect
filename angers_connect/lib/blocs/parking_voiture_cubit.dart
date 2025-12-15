import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/parking_voiture.dart';
import '../repositories/parking_voiture_repository.dart';

class ParkingVoitureCubit extends Cubit<List<ParkingVoiture>> {
  final ParkingVoitureRepository _repository;

  ParkingVoitureCubit(this._repository) : super([]) {
    fetchParkings();
  }

  Future<void> fetchParkings() async {
    try {
      final parkings = await _repository.fetchParkingVoitures();
      emit(parkings);
    } catch (e) {
      emit([]);
    }
  }
}
