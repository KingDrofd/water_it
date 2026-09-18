import 'package:water_it/features/plants/domain/entities/plant.dart';

/// Pure occurrence math for weekly watering reminders, shared by the home
/// strip and the plant library.
class WateringSchedule {
  const WateringSchedule._();

  static DateTime? nextOccurrence(WateringReminder reminder, DateTime now) {
    if (reminder.weekdays.isEmpty) {
      return null;
    }
    final time =
        reminder.preferredTime ?? DateTime(now.year, now.month, now.day, 9);
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

  /// The most recent scheduled occurrence at or before [now] — the due moment
  /// a completion has to cover for the reminder to not be overdue.
  static DateTime? previousOccurrence(WateringReminder reminder, DateTime now) {
    if (reminder.weekdays.isEmpty) {
      return null;
    }
    final time =
        reminder.preferredTime ?? DateTime(now.year, now.month, now.day, 9);
    final hour = time.hour;
    final minute = time.minute;

    DateTime? best;
    for (final weekday in reminder.weekdays) {
      final delta = (now.weekday - weekday + 7) % 7;
      var candidate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      ).subtract(Duration(days: delta));
      if (candidate.isAfter(now)) {
        candidate = candidate.subtract(const Duration(days: 7));
      }
      if (best == null || candidate.isAfter(best)) {
        best = candidate;
      }
    }
    return best;
  }

  /// The due moment a reminder has missed, or null when it is on track.
  ///
  /// A due moment that falls at or before the reminder's creation is ignored:
  /// a freshly created reminder has not missed the occurrence that happened
  /// earlier in the week, before it existed.
  static DateTime? overdueSince(
    WateringReminder reminder,
    DateTime? lastCompleted,
    DateTime now,
  ) {
    final lastDue = previousOccurrence(reminder, now);
    if (lastDue == null) {
      return null;
    }
    final createdAt = reminder.createdAt;
    if (createdAt != null && !lastDue.isAfter(createdAt)) {
      return null;
    }
    if (lastCompleted == null || lastCompleted.isBefore(lastDue)) {
      return lastDue;
    }
    return null;
  }

  /// True when any of the plant's reminders has missed its last due moment.
  static bool isPlantOverdue(
    List<WateringReminder> reminders,
    DateTime? lastCompleted,
    DateTime now,
  ) {
    for (final reminder in reminders) {
      if (overdueSince(reminder, lastCompleted, now) != null) {
        return true;
      }
    }
    return false;
  }
}
