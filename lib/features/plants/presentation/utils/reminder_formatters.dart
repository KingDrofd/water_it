import 'package:intl/intl.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';

String formatReminderSubtitle(WateringReminder reminder) {
  final days = reminder.weekdays;
  final dayLabel = days.isEmpty ? null : formatWeekdays(days);
  final timeLabel = reminder.preferredTime != null
      ? DateFormat('h:mm a').format(reminder.preferredTime!)
      : null;

  if (dayLabel != null && timeLabel != null) {
    return '$dayLabel - $timeLabel';
  }
  if (dayLabel != null) {
    return dayLabel;
  }
  if (timeLabel != null) {
    return timeLabel;
  }
  return 'Every ${reminder.frequencyDays} days';
}

String formatWeekdays(List<int> days) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final ordered = days.toList()..sort();
  return ordered
      .where((day) => day >= 1 && day <= 7)
      .map((day) => labels[day - 1])
      .join(', ');
}
