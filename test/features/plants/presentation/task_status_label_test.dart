import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/services/care_task_schedule.dart';
import 'package:water_it/features/plants/presentation/utils/task_status_label.dart';

void main() {
  final now = DateTime(2026, 9, 21, 9, 41);

  TaskStatus status(TaskDueState state, DateTime dueAt,
      {CareTaskType type = CareTaskType.water}) {
    return TaskStatus(
      task: CareTask(id: 't', plantId: 'p', type: type),
      state: state,
      dueAt: dueAt,
    );
  }

  test('overdue and today', () {
    expect(
      taskStatusLabel(status(TaskDueState.overdue, DateTime(2026, 9, 19)), now),
      'Water · overdue',
    );
    expect(
      taskStatusLabel(
        status(TaskDueState.dueToday, DateTime(2026, 9, 21, 18),
            type: CareTaskType.mist),
        now,
      ),
      'Mist today',
    );
  });

  test('upcoming in days and weeks', () {
    expect(
      taskStatusLabel(status(TaskDueState.upcoming, DateTime(2026, 9, 22, 8)), now),
      'Water tomorrow',
    );
    expect(
      taskStatusLabel(status(TaskDueState.upcoming, DateTime(2026, 9, 23)), now),
      'Water in 2 days',
    );
    expect(
      taskStatusLabel(
        status(TaskDueState.upcoming, DateTime(2026, 9, 28),
            type: CareTaskType.fertilize),
        now,
      ),
      'Fertilize in 1 wk',
    );
    expect(
      taskStatusLabel(status(TaskDueState.upcoming, DateTime(2026, 10, 12)), now),
      'Water in 3 wks',
    );
  });
}
