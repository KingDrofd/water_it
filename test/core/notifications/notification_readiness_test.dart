import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/core/notifications/notification_service.dart';

void main() {
  NotificationReadiness readiness({
    bool remindersEnabled = true,
    bool notificationsAllowed = true,
    bool exactAlarmsAllowed = true,
    bool batteryUnrestricted = true,
  }) {
    return NotificationReadiness(
      remindersEnabled: remindersEnabled,
      notificationsAllowed: notificationsAllowed,
      exactAlarmsAllowed: exactAlarmsAllowed,
      batteryUnrestricted: batteryUnrestricted,
    );
  }

  test('everything granted needs no attention', () {
    final state = readiness();

    expect(state.blocked, isFalse);
    expect(state.batteryRestricted, isFalse);
    expect(state.imprecise, isFalse);
    expect(state.needsAttention, isFalse);
  });

  test('notifications denied is blocked, not merely imprecise', () {
    final state = readiness(notificationsAllowed: false);

    expect(state.blocked, isTrue);
    expect(state.imprecise, isFalse);
    expect(state.needsAttention, isTrue);
  });

  test('battery optimisation is a delivery problem, not a timing one', () {
    final state = readiness(batteryUnrestricted: false);

    expect(state.blocked, isFalse);
    expect(state.batteryRestricted, isTrue);
    expect(state.imprecise, isFalse);
    expect(state.needsAttention, isTrue);
  });

  test('exact alarms denied is imprecise only', () {
    final state = readiness(exactAlarmsAllowed: false);

    expect(state.blocked, isFalse);
    expect(state.batteryRestricted, isFalse);
    expect(state.imprecise, isTrue);
    expect(state.needsAttention, isTrue);
  });

  test('battery and timing problems are reported independently', () {
    final state = readiness(
      exactAlarmsAllowed: false,
      batteryUnrestricted: false,
    );

    expect(state.batteryRestricted, isTrue);
    expect(state.imprecise, isTrue);
  });

  test('blocked notifications suppress the lesser complaints', () {
    // Nothing arrives at all, so battery/timing advice would be noise.
    final state = readiness(
      notificationsAllowed: false,
      exactAlarmsAllowed: false,
      batteryUnrestricted: false,
    );

    expect(state.blocked, isTrue);
    expect(state.batteryRestricted, isFalse);
    expect(state.imprecise, isFalse);
  });

  test('reminders switched off in-app never asks for permissions', () {
    final state = readiness(
      remindersEnabled: false,
      notificationsAllowed: false,
      exactAlarmsAllowed: false,
      batteryUnrestricted: false,
    );

    expect(state.blocked, isFalse);
    expect(state.batteryRestricted, isFalse);
    expect(state.imprecise, isFalse);
    expect(state.needsAttention, isFalse);
  });
}
