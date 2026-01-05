import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/parking_voiture.dart';
import '../repositories/parking_voiture_repository.dart';

class ParkingVoitureCubit extends Cubit<List<ParkingVoiture>> {
  final ParkingVoitureRepository _repository;
  Timer? _timer;

  ParkingVoitureCubit(this._repository) : super([]) {
    fetchParkings();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => fetchParkings());
  }

  Future<void> fetchParkings() async {
    try {
      final parkings = await _repository.fetchParkingVoitures();
      emit(parkings);
    } catch (e) {
      emit([]);
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
