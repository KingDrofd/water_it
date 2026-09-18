import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/services/watering_schedule.dart';

void main() {
  // Thursday 10:00. A Monday reminder's previous occurrence is 3 days back.
  final now = DateTime(2026, 9, 17, 10);

  WateringReminder reminder({DateTime? createdAt}) {
    return WateringReminder(
      id: 'r1',
      plantId: 'p1',
      frequencyDays: 7,
      weekdays: const [1], // Monday
      preferredTime: DateTime(2026, 1, 1, 9),
      createdAt: createdAt,
    );
  }

  test('a reminder created today is not overdue for a due moment that '
      'passed before it existed', () {
    final justCreated = reminder(createdAt: now.subtract(const Duration(minutes: 5)));

    expect(
      WateringSchedule.overdueSince(justCreated, null, now),
      isNull,
    );
    expect(
      WateringSchedule.isPlantOverdue([justCreated], null, now),
      isFalse,
    );
  });

  test('an older reminder with no completion is overdue', () {
    final old = reminder(createdAt: DateTime(2026, 8, 1));

    expect(
      WateringSchedule.overdueSince(old, null, now),
      DateTime(2026, 9, 14, 9), // the Monday just gone
    );
    expect(WateringSchedule.isPlantOverdue([old], null, now), isTrue);
  });

  test('a completion after the due moment clears overdue', () {
    final old = reminder(createdAt: DateTime(2026, 8, 1));

    expect(
      WateringSchedule.overdueSince(old, DateTime(2026, 9, 15), now),
      isNull,
    );
  });

  test('a completion before the due moment leaves it overdue', () {
    final old = reminder(createdAt: DateTime(2026, 8, 1));

    expect(
      WateringSchedule.overdueSince(old, DateTime(2026, 9, 10), now),
      isNotNull,
    );
  });

  test('a reminder created exactly at the due moment is not overdue for it',
      () {
    final atDue = reminder(createdAt: DateTime(2026, 9, 14, 9));

    expect(WateringSchedule.overdueSince(atDue, null, now), isNull);
  });

  test('a reminder created just before the due moment is still overdue', () {
    final beforeDue = reminder(createdAt: DateTime(2026, 9, 14, 8, 59));

    expect(WateringSchedule.overdueSince(beforeDue, null, now), isNotNull);
  });

  test('legacy reminders without a creation time keep the old behaviour', () {
    // Pre-v6 rows are backfilled by the migration, but a null must not crash.
    expect(WateringSchedule.overdueSince(reminder(), null, now), isNotNull);
  });

  test('a reminder with no weekdays is never overdue', () {
    const noDays = WateringReminder(
      id: 'r2',
      plantId: 'p1',
      frequencyDays: 7,
    );

    expect(WateringSchedule.overdueSince(noDays, null, now), isNull);
  });
}
