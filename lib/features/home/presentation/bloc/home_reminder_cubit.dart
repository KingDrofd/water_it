import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/features/home/presentation/models/home_reminder_item.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/services/care_task_schedule.dart';
import 'package:water_it/features/plants/domain/usecases/get_all_care_tasks.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_care_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/domain/usecases/get_rooms.dart';
import 'package:water_it/features/plants/domain/usecases/log_care_event.dart';

enum HomeReminderStatus { initial, loading, loaded, failure }

class HomeReminderState extends Equatable {
  const HomeReminderState({
    this.status = HomeReminderStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final HomeReminderStatus status;

  /// Every task due today or overdue, overdue first.
  final List<HomeReminderItem> items;
  final String? errorMessage;

  HomeReminderState copyWith({
    HomeReminderStatus? status,
    List<HomeReminderItem>? items,
    String? errorMessage,
  }) {
    return HomeReminderState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}

/// Builds the Home "Due today" list across every care task type.
class HomeReminderCubit extends Cubit<HomeReminderState> {
  HomeReminderCubit(
    this._getPlants,
    this._getAllCareTasks,
    this._getLatestCareEvents,
    this._getRooms,
    this._logCareEvent, {
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const HomeReminderState());

  final GetPlants _getPlants;
  final GetAllCareTasks _getAllCareTasks;
  final GetLatestCareEvents _getLatestCareEvents;
  final GetRooms _getRooms;
  final LogCareEvent _logCareEvent;
  final DateTime Function() _clock;
  static const Uuid _uuid = Uuid();

  Future<void> loadNextReminders() async {
    emit(state.copyWith(status: HomeReminderStatus.loading, errorMessage: null));
    try {
      final plants = await _getPlants();
      final tasks = await _getAllCareTasks();
      final latest = await _getLatestCareEvents();
      final rooms = await _getRooms();
      final now = _clock();

      final plantsById = {for (final p in plants) p.id: p};
      final roomNames = {for (final r in rooms) r.id: r.name};
      final items = <HomeReminderItem>[];

      for (final task in tasks) {
        final plant = plantsById[task.plantId];
        if (plant == null) {
          continue;
        }
        final status = CareTaskSchedule.status(
          task,
          latest[plant.id]?[task.type.name],
          now,
        );
        if (status == null || !status.needsCare) {
          continue;
        }
        items.add(
          HomeReminderItem(
            plantId: plant.id,
            plantName: plant.name,
            taskId: task.id,
            type: task.type,
            label: task.label,
            roomName: roomNames[plant.roomId],
            dueAt: status.dueAt,
            isOverdue: status.state == TaskDueState.overdue,
          ),
        );
      }

      items.sort((a, b) {
        if (a.isOverdue != b.isOverdue) {
          return a.isOverdue ? -1 : 1;
        }
        return a.dueAt.compareTo(b.dueAt);
      });
      emit(state.copyWith(status: HomeReminderStatus.loaded, items: items));
    } catch (error) {
      emit(
        state.copyWith(
          status: HomeReminderStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Logs a completion of [item]'s task and refreshes the list.
  Future<void> markDone(HomeReminderItem item) async {
    try {
      await _logCareEvent(
        CareEvent(
          id: _uuid.v4(),
          plantId: item.plantId,
          taskId: item.taskId,
          type: item.type.name,
          completedAt: _clock(),
          source: CareEventSource.home,
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return;
    }
    await loadNextReminders();
  }
}
