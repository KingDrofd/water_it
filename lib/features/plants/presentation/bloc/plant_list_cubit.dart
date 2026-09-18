import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/services/reminder_scheduler.dart';
import 'package:water_it/features/plants/domain/services/watering_schedule.dart';
import 'package:water_it/features/plants/domain/usecases/delete_plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_water_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';

enum PlantListStatus { initial, loading, loaded, empty, failure }

class PlantListState extends Equatable {
  const PlantListState({
    this.status = PlantListStatus.initial,
    this.plants = const [],
    this.overduePlantIds = const {},
    this.errorMessage,
  });

  final PlantListStatus status;
  final List<Plant> plants;
  final Set<String> overduePlantIds;
  final String? errorMessage;

  PlantListState copyWith({
    PlantListStatus? status,
    List<Plant>? plants,
    Set<String>? overduePlantIds,
    String? errorMessage,
  }) {
    return PlantListState(
      status: status ?? this.status,
      plants: plants ?? this.plants,
      overduePlantIds: overduePlantIds ?? this.overduePlantIds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plants, overduePlantIds, errorMessage];
}

class PlantListCubit extends Cubit<PlantListState> {
  PlantListCubit(
    this._getPlants,
    this._deletePlant,
    this._getLatestWaterEvents,
    this._reminderScheduler,
  ) : super(const PlantListState());

  final GetPlants _getPlants;
  final DeletePlant _deletePlant;
  final GetLatestWaterEvents _getLatestWaterEvents;
  final ReminderScheduler _reminderScheduler;

  Future<void> loadPlants() async {
    emit(state.copyWith(status: PlantListStatus.loading, errorMessage: null));
    try {
      final plants = await _getPlants();
      final latestEvents = await _getLatestWaterEvents();
      final now = DateTime.now();
      final overdueIds = {
        for (final plant in plants)
          if (WateringSchedule.isPlantOverdue(
            plant.reminders,
            latestEvents[plant.id],
            now,
          ))
            plant.id,
      };
      emit(
        state.copyWith(
          status: plants.isEmpty ? PlantListStatus.empty : PlantListStatus.loaded,
          plants: plants,
          overduePlantIds: overdueIds,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PlantListStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      return;
    }

    try {
      await _reminderScheduler.rescheduleAll();
    } catch (_) {
      // Ignore notification scheduling failures to avoid breaking plant loads.
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
