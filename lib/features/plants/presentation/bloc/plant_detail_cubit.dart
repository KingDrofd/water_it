import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_plant.dart';

enum PlantDetailStatus { initial, loading, loaded, notFound, failure }

class PlantDetailState extends Equatable {
  const PlantDetailState({
    this.status = PlantDetailStatus.initial,
    this.plant,
    this.errorMessage,
  });

  final PlantDetailStatus status;
  final Plant? plant;
  final String? errorMessage;

  PlantDetailState copyWith({
    PlantDetailStatus? status,
    Plant? plant,
    bool clearPlant = false,
    String? errorMessage,
  }) {
    return PlantDetailState(
      status: status ?? this.status,
      plant: clearPlant ? null : (plant ?? this.plant),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plant, errorMessage];
}

class PlantDetailCubit extends Cubit<PlantDetailState> {
  PlantDetailCubit(this._getPlant) : super(const PlantDetailState());

  final GetPlant _getPlant;

  Future<void> loadPlant(String id) async {
    emit(
      state.copyWith(
        status: PlantDetailStatus.loading,
        errorMessage: null,
        clearPlant: true,
      ),
    );
    try {
      final plant = await _getPlant(id);
      if (plant == null) {
        emit(
          state.copyWith(
            status: PlantDetailStatus.notFound,
            clearPlant: true,
          ),
        );
      } else {
        emit(state.copyWith(status: PlantDetailStatus.loaded, plant: plant));
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: PlantDetailStatus.failure,
          errorMessage: error.toString(),
          clearPlant: true,
        ),
      );
    }
  }
}
