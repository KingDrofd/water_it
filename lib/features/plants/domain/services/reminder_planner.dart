import 'package:water_it/core/notifications/notification_payload.dart';
import 'package:water_it/core/notifications/reminder_plan.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';

/// Pure planning logic: turns care tasks + completion history into the
/// concrete list of notifications to schedule. No plugin, no I/O.
class ReminderPlanner {
  const ReminderPlanner._();

  /// Fixed notification id for the daily summary.
  static const int dailySummaryId = 3;

  /// Hour of the daily summary per the Care System spec.
  static const int dailySummaryHour = 8;

  static const Map<CareTaskType, String> _defaultBodies = {
    CareTaskType.water: 'Time to water your plant.',
    CareTaskType.fertilize: 'Time to fertilize your plant.',
    CareTaskType.mist: 'Time to mist your plant.',
    CareTaskType.repot: 'Time to repot your plant.',
    CareTaskType.prune: 'Time to prune your plant.',
    CareTaskType.custom: 'Time for some plant care.',
  };

  static String titleFor(CareTask task, String plantName) {
    if (task.type == CareTaskType.custom) {
      return '${task.label} — $plantName';
    }
    return '${task.label} $plantName';
  }

  static String bodyFor(CareTask task) {
    final notes = task.notes?.trim();
    if (notes != null && notes.isNotEmpty) {
      return notes;
    }
    return _defaultBodies[task.type]!;
  }

  /// Builds every task notification. [latestEvents] is plantId -> type ->
  /// last completion, used to anchor interval schedules.
  static List<ReminderPlan> buildPlans({
    required List<Plant> plants,
    required List<CareTask> tasks,
    required Map<String, Map<String, DateTime>> latestEvents,
    required DateTime now,
  }) {
    final plantNames = {for (final p in plants) p.id: p.name};
    final plans = <ReminderPlan>[];

    for (final task in tasks) {
      final plantName = plantNames[task.plantId];
      if (plantName == null || !task.active) {
        continue;
      }
      final title = titleFor(task, plantName);
      final body = bodyFor(task);
      final hour = task.preferredTime?.hour ?? 9;
      final minute = task.preferredTime?.minute ?? 0;
      final payload = NotificationPayload(
        plantId: task.plantId,
        taskId: task.id,
        type: task.type.name,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        intervalDays: task.scheduleType == CareScheduleType.interval
            ? task.intervalDays
            : 0,
      );

      switch (task.scheduleType) {
        case CareScheduleType.weekly:
          for (final weekday in task.weekdays) {
            if (weekday < 1 || weekday > 7) continue;
            plans.add(
              ReminderPlan(
                id: notificationId('${task.id}-w$weekday'),
                title: title,
                body: body,
                scheduledAt: _nextWeekdayOccurrence(
                  now,
                  weekday: weekday,
                  hour: hour,
                  minute: minute,
                ),
                repeatsWeekly: true,
                payload: payload,
              ),
            );
          }
        case CareScheduleType.interval:
          if (task.intervalDays < 1) continue;
          plans.add(
            ReminderPlan(
              id: notificationId('${task.id}-interval'),
              title: title,
              body: body,
              scheduledAt: nextIntervalOccurrence(
                // Matches CareTaskSchedule: a never-done task counts
                // from creation rather than being due at once.
                anchor: latestEvents[task.plantId]?[task.type.name] ??
                    task.createdAt,
                intervalDays: task.intervalDays,
                hour: hour,
                minute: minute,
                now: now,
              ),
              payload: payload,
            ),
          );
      }
    }
    return plans;
  }

  /// The daily summary for the next 08:00, or null when nothing is due that
  /// day (no notification beats a "0 plants need care" notification).
  static ReminderPlan? buildDailySummary({
    required List<Plant> plants,
    required List<CareTask> tasks,
    required Map<String, Map<String, DateTime>> latestEvents,
    required DateTime now,
  }) {
    var fireAt =
        DateTime(now.year, now.month, now.day, dailySummaryHour);
    if (!fireAt.isAfter(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }

    final plantNames = {for (final p in plants) p.id: p.name};
    final dueNames = <String>{};
    for (final task in tasks) {
      final plantName = plantNames[task.plantId];
      if (plantName == null || !task.active) {
        continue;
      }
      if (_isDueOn(task, latestEvents, fireAt)) {
        dueNames.add(plantName);
      }
    }
    if (dueNames.isEmpty) {
      return null;
    }

    final names = dueNames.toList();
    final shown = names.take(3).join(', ');
    final suffix = names.length > 3 ? ', +${names.length - 3} more' : '';
    final body = names.length == 1
        ? '1 plant needs care today: $shown'
        : '${names.length} plants need care today: $shown$suffix';

    return ReminderPlan(
      id: dailySummaryId,
      title: 'Water It',
      body: body,
      scheduledAt: fireAt,
      payload: NotificationPayload(
        plantId: '',
        type: NotificationPayload.summaryType,
        title: 'Water It',
        body: body,
        hour: dailySummaryHour,
      ),
    );
  }

  static bool _isDueOn(
    CareTask task,
    Map<String, Map<String, DateTime>> latestEvents,
    DateTime day,
  ) {
    switch (task.scheduleType) {
      case CareScheduleType.weekly:
        return task.weekdays.contains(day.weekday);
      case CareScheduleType.interval:
        if (task.intervalDays < 1) return false;
        final anchor =
            latestEvents[task.plantId]?[task.type.name] ?? task.createdAt;
        if (anchor == null) {
          // Never completed: treat as due.
          return true;
        }
        final due = DateTime(anchor.year, anchor.month, anchor.day)
            .add(Duration(days: task.intervalDays));
        final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
        return !due.isAfter(endOfDay);
    }
  }

  /// Next due moment for an interval task: anchor + N days at the preferred
  /// time. Overdue (or never completed) tasks fire at the next occurrence of
  /// the preferred time instead of a moment in the past.
  static DateTime nextIntervalOccurrence({
    required DateTime? anchor,
    required int intervalDays,
    required int hour,
    required int minute,
    required DateTime now,
  }) {
    if (anchor != null) {
      final due = DateTime(anchor.year, anchor.month, anchor.day, hour, minute)
          .add(Duration(days: intervalDays));
      if (due.isAfter(now)) {
        return due;
      }
    }
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }

  static DateTime _nextWeekdayOccurrence(
    DateTime now, {
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    final daysAhead = (weekday - now.weekday) % 7;
    var scheduled = today.add(Duration(days: daysAhead));
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }

  /// Stable non-negative notification id from a string key.
  static int notificationId(String key) => key.hashCode & 0x7fffffff;
}
