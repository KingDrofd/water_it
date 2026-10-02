import 'package:water_it/features/plants/domain/services/care_task_schedule.dart';

/// Library card status line: "Water · overdue", "Mist today",
/// "Water tomorrow", "Water in 2 days", "Fertilize in 1 wk".
String taskStatusLabel(TaskStatus status, DateTime now) {
  final label = status.task.label;
  switch (status.state) {
    case TaskDueState.overdue:
      return '$label · overdue';
    case TaskDueState.dueToday:
      return '$label today';
    case TaskDueState.upcoming:
      final days = CareTaskSchedule.daysUntil(status, now);
      if (days <= 1) {
        return '$label tomorrow';
      }
      if (days < 7) {
        return '$label in $days days';
      }
      final weeks = (days / 7).round();
      return '$label in $weeks wk${weeks == 1 ? '' : 's'}';
  }
}
