import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/services/care_task_schedule.dart';
import 'package:water_it/features/plants/domain/services/reminder_scheduler.dart';
import 'package:water_it/features/plants/domain/usecases/delete_plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_all_care_tasks.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_care_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';

enum PlantListStatus { initial, loading, loaded, empty, failure }

class PlantListState extends Equatable {
  const PlantListState({
    this.status = PlantListStatus.initial,
    this.plants = const [],
    this.nextTasks = const {},
    this.errorMessage,
  });

  final PlantListStatus status;
  final List<Plant> plants;

  /// Each plant's most urgent care task (plants without tasks are absent).
  final Map<String, TaskStatus> nextTasks;
  final String? errorMessage;

  Set<String> get overduePlantIds => {
        for (final entry in nextTasks.entries)
          if (entry.value.state == TaskDueState.overdue) entry.key,
      };

  PlantListState copyWith({
    PlantListStatus? status,
    List<Plant>? plants,
    Map<String, TaskStatus>? nextTasks,
    String? errorMessage,
  }) {
    return PlantListState(
      status: status ?? this.status,
      plants: plants ?? this.plants,
      nextTasks: nextTasks ?? this.nextTasks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plants, nextTasks, errorMessage];
}

class PlantListCubit extends Cubit<PlantListState> {
  PlantListCubit(
    this._getPlants,
    this._deletePlant,
    this._getAllCareTasks,
    this._getLatestCareEvents,
    this._reminderScheduler, {
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const PlantListState());

  final GetPlants _getPlants;
  final DeletePlant _deletePlant;
  final GetAllCareTasks _getAllCareTasks;
  final GetLatestCareEvents _getLatestCareEvents;
  final ReminderScheduler _reminderScheduler;
  final DateTime Function() _clock;

  Future<void> loadPlants() async {
    emit(state.copyWith(status: PlantListStatus.loading, errorMessage: null));
    try {
      final plants = await _getPlants();
      final tasks = await _getAllCareTasks();
      final latest = await _getLatestCareEvents();
      final now = _clock();
      final nextTasks = <String, TaskStatus>{};
      for (final task in tasks) {
        final status = CareTaskSchedule.status(
          task,
          latest[task.plantId]?[task.type.name],
          now,
        );
        if (status == null) {
          continue;
        }
        final current = nextTasks[task.plantId];
        if (current == null || _moreUrgent(status, current)) {
          nextTasks[task.plantId] = status;
        }
      }
      emit(
        state.copyWith(
          status: plants.isEmpty ? PlantListStatus.empty : PlantListStatus.loaded,
          plants: plants,
          nextTasks: nextTasks,
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

  /// Overdue beats due today beats upcoming; within a state, earliest wins.
  static bool _moreUrgent(TaskStatus a, TaskStatus b) {
    if (a.state != b.state) {
      return a.state.index < b.state.index;
    }
    return a.dueAt.isBefore(b.dueAt);
  }
}
