import 'package:water_it/features/plants/domain/entities/care_task.dart';

/// One row of the Home "Due today" list: a single care task that is due
/// today or overdue.
class HomeReminderItem {
  const HomeReminderItem({
    required this.plantId,
    required this.plantName,
    required this.taskId,
    required this.type,
    required this.label,
    required this.dueAt,
    this.roomName,
    this.isOverdue = false,
  });

  final String plantId;
  final String plantName;
  final String taskId;
  final CareTaskType type;

  /// Task display name ("Water", or a custom task's own label).
  final String label;
  final String? roomName;

  /// The missed due moment when overdue, otherwise today's due moment.
  final DateTime dueAt;
  final bool isOverdue;
}
