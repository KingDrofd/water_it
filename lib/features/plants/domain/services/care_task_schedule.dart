import 'package:water_it/features/plants/domain/entities/care_task.dart';

/// Declared most to least urgent; callers rank statuses by [index].
enum TaskDueState { overdue, dueToday, upcoming }

/// Where one task stands right now, for the Home list and library cards.
class TaskStatus {
  const TaskStatus({
    required this.task,
    required this.state,
    required this.dueAt,
  });

  final CareTask task;
  final TaskDueState state;

  /// The missed due moment when overdue, otherwise the next one.
  final DateTime dueAt;

  bool get needsCare => state != TaskDueState.upcoming;
}

/// Pure due-date rules for care tasks of every type and schedule.
///
/// A task only becomes overdue once the *day* of a missed due moment has
/// passed; a task due at 08:00 is still simply "due today" at 09:41. And a
/// completion anywhere on the due day covers it, so watering in the morning
/// ahead of an evening reminder counts.
class CareTaskSchedule {
  const CareTaskSchedule._();

  static const int _defaultHour = 9;

  /// Status of [task] given the plant's latest completion of this task's
  /// type, or null for a paused or unschedulable task.
  static TaskStatus? status(
    CareTask task,
    DateTime? lastDone,
    DateTime now,
  ) {
    if (!task.active) {
      return null;
    }
    switch (task.scheduleType) {
      case CareScheduleType.weekly:
        return _weekly(task, lastDone, now);
      case CareScheduleType.interval:
        return _interval(task, lastDone, now);
    }
  }

  static TaskStatus? _weekly(CareTask task, DateTime? lastDone, DateTime now) {
    final days = task.weekdays.where((d) => d >= 1 && d <= 7).toSet();
    if (days.isEmpty) {
      return null;
    }
    final today = _day(now);

    // Most recent scheduled day strictly before today.
    for (var back = 1; back <= 7; back++) {
      final day = today.subtract(Duration(days: back));
      if (!days.contains(day.weekday)) {
        continue;
      }
      final missed = _at(task, day);
      final createdAt = task.createdAt;
      final predatesTask = createdAt != null && !missed.isAfter(createdAt);
      if (!predatesTask && !_covers(lastDone, day)) {
        return TaskStatus(task: task, state: TaskDueState.overdue, dueAt: missed);
      }
      break;
    }

    if (days.contains(today.weekday) && !_covers(lastDone, today)) {
      return TaskStatus(
        task: task,
        state: TaskDueState.dueToday,
        dueAt: _at(task, today),
      );
    }

    for (var ahead = 1; ahead <= 7; ahead++) {
      final day = today.add(Duration(days: ahead));
      if (days.contains(day.weekday)) {
        return TaskStatus(
          task: task,
          state: TaskDueState.upcoming,
          dueAt: _at(task, day),
        );
      }
    }
    return null;
  }

  static TaskStatus? _interval(
    CareTask task,
    DateTime? lastDone,
    DateTime now,
  ) {
    if (task.intervalDays < 1) {
      return null;
    }
    final today = _day(now);
    // Counts from the last completion, or from creation for a task that has
    // never been done - a brand new task is not due immediately.
    final anchor = lastDone ?? task.createdAt;
    if (anchor == null) {
      return TaskStatus(
        task: task,
        state: TaskDueState.dueToday,
        dueAt: _at(task, today),
      );
    }
    final dueDay = _day(anchor).add(Duration(days: task.intervalDays));
    final state = dueDay.isBefore(today)
        ? TaskDueState.overdue
        : dueDay == today
            ? TaskDueState.dueToday
            : TaskDueState.upcoming;
    return TaskStatus(task: task, state: state, dueAt: _at(task, dueDay));
  }

  /// Whole calendar days from today until [status]'s due moment; negative
  /// when overdue.
  static int daysUntil(TaskStatus status, DateTime now) {
    final from = _day(now);
    final to = _day(status.dueAt);
    return DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;
  }

  /// A completion anywhere on or after [day] covers that day's due moment.
  static bool _covers(DateTime? lastDone, DateTime day) =>
      lastDone != null && !lastDone.isBefore(day);

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  static DateTime _at(CareTask task, DateTime day) => DateTime(
        day.year,
        day.month,
        day.day,
        task.preferredTime?.hour ?? _defaultHour,
        task.preferredTime?.minute ?? 0,
      );
}
