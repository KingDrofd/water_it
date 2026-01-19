import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/home/presentation/models/home_reminder_item.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';

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
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}

class HomeReminderCubit extends Cubit<HomeReminderState> {
  HomeReminderCubit(this._getPlants) : super(const HomeReminderState());

  final GetPlants _getPlants;

  Future<void> loadNextReminders() async {
    emit(state.copyWith(status: HomeReminderStatus.loading, errorMessage: null));
    try {
      final plants = await _getPlants();
      final items = _buildItems(plants);
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

  List<HomeReminderItem> _buildItems(List<Plant> plants) {
    final now = DateTime.now();
    final candidates = <HomeReminderItem>[];
    for (final plant in plants) {
      for (final reminder in plant.reminders) {
        final next = _nextOccurrence(reminder, now);
        if (next == null) {
          continue;
        }
        final task = reminder.notes?.trim();
        candidates.add(
          HomeReminderItem(
            plantId: plant.id,
            plantName: plant.name,
            task: task == null || task.isEmpty ? 'Watering' : task,
            dueAt: next,
            icon: Icons.water_drop,
          ),
        );
      }
    }
    candidates.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    if (candidates.length <= 3) {
      return candidates;
    }
    return candidates.take(3).toList();
  }

  DateTime? _nextOccurrence(WateringReminder reminder, DateTime now) {
    if (reminder.weekdays.isEmpty) {
      return null;
    }
    final time = reminder.preferredTime ?? DateTime(now.year, now.month, now.day, 9);
    final hour = time.hour;
    final minute = time.minute;

    DateTime? best;
    for (final weekday in reminder.weekdays) {
      final delta = (weekday - now.weekday + 7) % 7;
      var candidate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).add(Duration(days: delta));
      if (delta == 0 && candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 7));
      }
      if (best == null || candidate.isBefore(best)) {
        best = candidate;
      }
    }
    return best;
  }
}
