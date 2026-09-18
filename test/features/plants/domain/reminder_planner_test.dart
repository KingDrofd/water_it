import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/core/notifications/notification_payload.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/services/reminder_planner.dart';

void main() {
  // A Tuesday, 10:00.
  final now = DateTime(2026, 8, 4, 10);

  const plants = [
    Plant(id: 'p1', name: 'Monstera'),
    Plant(id: 'p2', name: 'Basil'),
  ];

  group('buildPlans', () {
    test('weekly task produces one repeating plan per weekday', () {
      final plans = ReminderPlanner.buildPlans(
        plants: plants,
        tasks: [
          CareTask(
            id: 't1',
            plantId: 'p1',
            type: CareTaskType.water,
            weekdays: const [1, 4],
            preferredTime: DateTime(2026, 1, 1, 8, 30),
          ),
        ],
        latestEvents: const {},
        now: now,
      );

      expect(plans.length, 2);
      expect(plans.every((p) => p.repeatsWeekly), isTrue);
      expect(plans.every((p) => p.title == 'Water Monstera'), isTrue);
      final weekdays = plans.map((p) => p.scheduledAt.weekday).toSet();
      expect(weekdays, {1, 4});
      for (final plan in plans) {
        expect(plan.scheduledAt.hour, 8);
        expect(plan.scheduledAt.minute, 30);
        expect(plan.scheduledAt.isAfter(now), isTrue);
      }
    });

    test('interval task anchors on the last completion', () {
      final plans = ReminderPlanner.buildPlans(
        plants: plants,
        tasks: const [
          CareTask(
            id: 't2',
            plantId: 'p2',
            type: CareTaskType.fertilize,
            scheduleType: CareScheduleType.interval,
            intervalDays: 10,
          ),
        ],
        latestEvents: {
          'p2': {'fertilize': DateTime(2026, 8, 1, 18)},
        },
        now: now,
      );

      final plan = plans.single;
      expect(plan.repeatsWeekly, isFalse);
      expect(plan.title, 'Fertilize Basil');
      // Aug 1 + 10 days at the default 9:00.
      expect(plan.scheduledAt, DateTime(2026, 8, 11, 9));
      expect(plan.payload.intervalDays, 10);
    });

    test('overdue interval task fires at the next preferred time instead',
        () {
      final plans = ReminderPlanner.buildPlans(
        plants: plants,
        tasks: const [
          CareTask(
            id: 't3',
            plantId: 'p1',
            type: CareTaskType.mist,
            scheduleType: CareScheduleType.interval,
            intervalDays: 3,
          ),
        ],
        latestEvents: {
          'p1': {'mist': DateTime(2026, 7, 1)},
        },
        now: now,
      );

      // Due moment long past; 9:00 today already gone at now=10:00 → tomorrow.
      expect(plans.single.scheduledAt, DateTime(2026, 8, 5, 9));
    });

    test('inactive tasks and tasks of unknown plants are skipped', () {
      final plans = ReminderPlanner.buildPlans(
        plants: plants,
        tasks: const [
          CareTask(id: 't4', plantId: 'p1', weekdays: [1], active: false),
          CareTask(id: 't5', plantId: 'ghost', weekdays: [1]),
        ],
        latestEvents: const {},
        now: now,
      );

      expect(plans, isEmpty);
    });

    test('custom task uses its label in the title', () {
      final plans = ReminderPlanner.buildPlans(
        plants: plants,
        tasks: const [
          CareTask(
            id: 't6',
            plantId: 'p1',
            type: CareTaskType.custom,
            customLabel: 'Rotate toward light',
            weekdays: [2],
          ),
        ],
        latestEvents: const {},
        now: now,
      );

      expect(plans.single.title, 'Rotate toward light — Monstera');
    });
  });

  group('buildDailySummary', () {
    test('lists plants due on the summary day', () {
      // now is Tuesday 10:00 → summary fires Wednesday 08:00 (weekday 3).
      final summary = ReminderPlanner.buildDailySummary(
        plants: plants,
        tasks: const [
          CareTask(id: 't1', plantId: 'p1', weekdays: [3]),
          CareTask(
            id: 't2',
            plantId: 'p2',
            type: CareTaskType.fertilize,
            scheduleType: CareScheduleType.interval,
            intervalDays: 5,
          ), // never completed → due
        ],
        latestEvents: const {},
        now: now,
      );

      expect(summary, isNotNull);
      expect(summary!.scheduledAt, DateTime(2026, 8, 5, 8));
      expect(summary.body, '2 plants need care today: Monstera, Basil');
      expect(summary.payload.type, NotificationPayload.summaryType);
    });

    test('uses singular phrasing for one plant', () {
      final summary = ReminderPlanner.buildDailySummary(
        plants: plants,
        tasks: const [
          CareTask(id: 't1', plantId: 'p1', weekdays: [3]),
        ],
        latestEvents: const {},
        now: now,
      );

      expect(summary!.body, '1 plant needs care today: Monstera');
    });

    test('returns null when nothing is due', () {
      final summary = ReminderPlanner.buildDailySummary(
        plants: plants,
        tasks: const [
          CareTask(id: 't1', plantId: 'p1', weekdays: [5]), // Friday only
        ],
        latestEvents: const {},
        now: now,
      );

      expect(summary, isNull);
    });

    test('summary scheduled for today when before 08:00', () {
      final early = DateTime(2026, 8, 4, 6);
      final summary = ReminderPlanner.buildDailySummary(
        plants: plants,
        tasks: const [
          CareTask(id: 't1', plantId: 'p1', weekdays: [2]), // Tuesday
        ],
        latestEvents: const {},
        now: early,
      );

      expect(summary!.scheduledAt, DateTime(2026, 8, 4, 8));
    });

    test('interval task completed recently is not due', () {
      final summary = ReminderPlanner.buildDailySummary(
        plants: plants,
        tasks: const [
          CareTask(
            id: 't2',
            plantId: 'p2',
            type: CareTaskType.fertilize,
            scheduleType: CareScheduleType.interval,
            intervalDays: 30,
          ),
        ],
        latestEvents: {
          'p2': {'fertilize': DateTime(2026, 8, 1)},
        },
        now: now,
      );

      expect(summary, isNull);
    });
  });

  group('nextIntervalOccurrence', () {
    test('future due moment is kept as-is', () {
      final next = ReminderPlanner.nextIntervalOccurrence(
        anchor: DateTime(2026, 8, 3),
        intervalDays: 7,
        hour: 9,
        minute: 0,
        now: now,
      );
      expect(next, DateTime(2026, 8, 10, 9));
    });

    test('no anchor falls back to next preferred time', () {
      final next = ReminderPlanner.nextIntervalOccurrence(
        anchor: null,
        intervalDays: 7,
        hour: 18,
        minute: 30,
        now: now,
      );
      // 18:30 today still ahead of 10:00.
      expect(next, DateTime(2026, 8, 4, 18, 30));
    });
  });
}
