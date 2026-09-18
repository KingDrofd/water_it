import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/features/home/presentation/models/home_reminder_item.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/services/watering_schedule.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_water_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/domain/usecases/log_care_event.dart';

enum HomeReminderStatus { initial, loading, loaded, failure }

class HomeReminderState extends Equatable {
  const HomeReminderState({
    this.status = HomeReminderStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final HomeReminderStatus status;
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

class HomeReminderCubit extends Cubit<HomeReminderState> {
  HomeReminderCubit(
    this._getPlants,
    this._getLatestWaterEvents,
    this._logCareEvent,
  ) : super(const HomeReminderState());

  final GetPlants _getPlants;
  final GetLatestWaterEvents _getLatestWaterEvents;
  final LogCareEvent _logCareEvent;
  static const Uuid _uuid = Uuid();

  Future<void> loadNextReminders() async {
    emit(state.copyWith(status: HomeReminderStatus.loading, errorMessage: null));
    try {
      final plants = await _getPlants();
      final latestEvents = await _getLatestWaterEvents();
      final items = _buildItems(plants, latestEvents);
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

  /// Logs a water event for [plantId] and refreshes the strip.
  Future<void> markDone(String plantId) async {
    try {
      await _logCareEvent(
        CareEvent(
          id: _uuid.v4(),
          plantId: plantId,
          completedAt: DateTime.now(),
          source: CareEventSource.home,
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return;
    }
    await loadNextReminders();
  }

  List<HomeReminderItem> _buildItems(
    List<Plant> plants,
    Map<String, DateTime> latestEvents,
  ) {
    final now = DateTime.now();
    final candidates = <HomeReminderItem>[];
    for (final plant in plants) {
      final lastDone = latestEvents[plant.id];
      for (final reminder in plant.reminders) {
        final next = WateringSchedule.nextOccurrence(reminder, now);
        if (next == null) {
          continue;
        }
        final overdueSince =
            WateringSchedule.overdueSince(reminder, lastDone, now);
        final isOverdue = overdueSince != null;
        final task = reminder.notes?.trim();
        candidates.add(
          HomeReminderItem(
            plantId: plant.id,
            plantName: plant.name,
            task: task == null || task.isEmpty ? 'Watering' : task,
            dueAt: overdueSince ?? next,
            icon: Icons.water_drop,
            isOverdue: isOverdue,
          ),
        );
      }
    }
    // Overdue first, then soonest due.
    candidates.sort((a, b) {
      if (a.isOverdue != b.isOverdue) {
        return a.isOverdue ? -1 : 1;
      }
      return a.dueAt.compareTo(b.dueAt);
    });
    if (candidates.length <= 3) {
      return candidates;
    }
    return candidates.take(3).toList();
  }
}
