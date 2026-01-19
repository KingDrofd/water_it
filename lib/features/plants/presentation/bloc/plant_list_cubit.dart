import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/usecases/delete_plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';

enum PlantListStatus { initial, loading, loaded, empty, failure }

class PlantListState extends Equatable {
  const PlantListState({
    this.status = PlantListStatus.initial,
    this.plants = const [],
    this.errorMessage,
  });

  final PlantListStatus status;
  final List<Plant> plants;
  final String? errorMessage;

  PlantListState copyWith({
    PlantListStatus? status,
    List<Plant>? plants,
    String? errorMessage,
  }) {
    return PlantListState(
      status: status ?? this.status,
      plants: plants ?? this.plants,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plants, errorMessage];
}

class PlantListCubit extends Cubit<PlantListState> {
  PlantListCubit(this._getPlants, this._deletePlant)
      : super(const PlantListState());

  final GetPlants _getPlants;
  final DeletePlant _deletePlant;

  Future<void> loadPlants() async {
    emit(state.copyWith(status: PlantListStatus.loading, errorMessage: null));
    try {
      final plants = await _getPlants();
      emit(
        state.copyWith(
          status: plants.isEmpty ? PlantListStatus.empty : PlantListStatus.loaded,
          plants: plants,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PlantListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> deletePlant(String id) async {
    emit(state.copyWith(status: PlantListStatus.loading, errorMessage: null));
    try {
      await _deletePlant(id);
      await loadPlants();
    } catch (error) {
      emit(
        state.copyWith(
          status: PlantListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
