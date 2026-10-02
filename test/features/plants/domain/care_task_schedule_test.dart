import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/services/care_task_schedule.dart';

void main() {
  // Monday 2026-09-21, 09:41 — the mockup's clock.
  final now = DateTime(2026, 9, 21, 9, 41);
  final longAgo = DateTime(2026, 8, 1);

  CareTask weekly(List<int> days, {DateTime? createdAt, int hour = 8}) {
    return CareTask(
      id: 't',
      plantId: 'p',
      weekdays: days,
      preferredTime: DateTime(2026, 1, 1, hour),
      createdAt: createdAt ?? longAgo,
    );
  }

  CareTask interval(int every, {DateTime? createdAt}) {
    return CareTask(
      id: 't',
      plantId: 'p',
      type: CareTaskType.fertilize,
      scheduleType: CareScheduleType.interval,
      intervalDays: every,
      createdAt: createdAt ?? longAgo,
    );
  }

  group('weekly', () {
    test('due earlier today is "due today", not overdue', () {
      // Last Monday was done, so only today's 08:00 is outstanding.
      final s = CareTaskSchedule.status(
        weekly([1]),
        DateTime(2026, 9, 14, 8),
        now,
      )!;

      expect(s.state, TaskDueState.dueToday);
      expect(s.dueAt, DateTime(2026, 9, 21, 8));
    });

    test('missed yesterday is overdue', () {
      final s = CareTaskSchedule.status(weekly([7]), null, now)!;

      expect(s.state, TaskDueState.overdue);
      expect(s.dueAt, DateTime(2026, 9, 20, 8));
    });

    test('completion on the due day covers it, even before the due time', () {
      final s = CareTaskSchedule.status(
        weekly([7], hour: 18),
        DateTime(2026, 9, 20, 7),
        now,
      )!;

      expect(s.state, TaskDueState.upcoming);
    });

    test('done today clears today and points at the next occurrence', () {
      final s = CareTaskSchedule.status(
        weekly([1, 4]),
        DateTime(2026, 9, 21, 7),
        now,
      )!;

      expect(s.state, TaskDueState.upcoming);
      expect(s.dueAt, DateTime(2026, 9, 24, 8)); // Thursday
    });

    test('an occurrence before the task existed is not overdue', () {
      final s = CareTaskSchedule.status(
        weekly([7], createdAt: DateTime(2026, 9, 21, 9)),
        null,
        now,
      )!;

      expect(s.state, TaskDueState.upcoming);
    });

    test('overdue wins over also being due today', () {
      final s = CareTaskSchedule.status(weekly([7, 1]), null, now)!;

      expect(s.state, TaskDueState.overdue);
    });
  });

  group('interval', () {
    test('counts from the last completion', () {
      final s = CareTaskSchedule.status(
        interval(10),
        DateTime(2026, 9, 11, 18),
        now,
      )!;

      expect(s.state, TaskDueState.dueToday);
    });

    test('past its day is overdue', () {
      final s = CareTaskSchedule.status(
        interval(3),
        DateTime(2026, 9, 10),
        now,
      )!;

      expect(s.state, TaskDueState.overdue);
      expect(CareTaskSchedule.daysUntil(s, now), -8);
    });

    test('a new task counts from creation instead of being due at once', () {
      final s = CareTaskSchedule.status(
        interval(30, createdAt: DateTime(2026, 9, 21, 9)),
        null,
        now,
      )!;

      expect(s.state, TaskDueState.upcoming);
      expect(CareTaskSchedule.daysUntil(s, now), 30);
    });
  });

  test('paused tasks have no status', () {
    final paused = weekly([1]).copyWith(active: false);

    expect(CareTaskSchedule.status(paused, null, now), isNull);
  });

  test('daysUntil counts calendar days, not 24-hour spans', () {
    final s = CareTaskSchedule.status(
      weekly([2], hour: 8),
      DateTime(2026, 9, 21, 7),
      now,
    )!;

    // Tomorrow at 08:00 is less than 24h away but still "in 1 day".
    expect(CareTaskSchedule.daysUntil(s, now), 1);
  });
}
