import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/features/plants/domain/repositories/care_log_repository.dart';
import 'package:water_it/features/plants/domain/repositories/care_task_repository.dart';
import 'package:water_it/features/plants/domain/services/reminder_planner.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';

/// Rebuilds the full notification schedule from current state. Called on
/// app launch, plant/task edits, completions, and settings changes — the
/// spec's rescheduling triggers.
class ReminderScheduler {
  ReminderScheduler(
    this._getPlants,
    this._careTaskRepository,
    this._careLogRepository,
    this._notificationService,
  );

  final GetPlants _getPlants;
  final CareTaskRepository _careTaskRepository;
  final CareLogRepository _careLogRepository;
  final NotificationService _notificationService;

  Future<void> rescheduleAll() async {
    final remindersEnabled = await AppSettings.getWateringRemindersEnabled();
    if (!remindersEnabled) {
      await _notificationService.cancelAll();
      return;
    }

    final plants = await _getPlants();
    final tasks = await _careTaskRepository.getAllTasks();
    final latestEvents = await _careLogRepository.getLatestEvents();
    final now = DateTime.now();

    final plans = ReminderPlanner.buildPlans(
      plants: plants,
      tasks: tasks,
      latestEvents: latestEvents,
      now: now,
    );

    if (await AppSettings.getDailySummaryEnabled()) {
      final summary = ReminderPlanner.buildDailySummary(
        plants: plants,
        tasks: tasks,
        latestEvents: latestEvents,
        now: now,
      );
      if (summary != null) {
        plans.add(summary);
      }
    }

    await _notificationService.applySchedule(plans);
    await AppSettings.setLastNotificationSchedule(DateTime.now());
  }
}
