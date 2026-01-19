import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/usecases/upsert_plant.dart';

enum PlantFormStatus { idle, saving, success, failure }

class PlantFormState extends Equatable {
  const PlantFormState({
    this.status = PlantFormStatus.idle,
    this.errorMessage,
  });

  final PlantFormStatus status;
  final String? errorMessage;

  PlantFormState copyWith({
    PlantFormStatus? status,
    String? errorMessage,
  }) {
    return PlantFormState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}

class PlantFormCubit extends Cubit<PlantFormState> {
  PlantFormCubit(this._upsertPlant) : super(const PlantFormState());

  final UpsertPlant _upsertPlant;

  Future<void> savePlant(Plant plant) async {
    emit(state.copyWith(status: PlantFormStatus.saving, errorMessage: null));
    try {
      await _upsertPlant(plant);
      emit(state.copyWith(status: PlantFormStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: PlantFormStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
