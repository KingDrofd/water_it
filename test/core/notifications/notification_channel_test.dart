import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/core/notifications/notification_channel.dart';
import 'package:water_it/core/notifications/notification_service.dart';

void main() {
  test('reminders use high importance so Android shows a heads-up popup', () {
    final android = NotificationChannelSpec.details().android!;

    expect(android.importance, Importance.high);
    expect(android.priority, Priority.high);
    expect(android.playSound, isTrue);
    expect(android.enableVibration, isTrue);
  });

  test('the retired default-importance channel is scheduled for deletion', () {
    // Channel importance is immutable once created, so the old channel must
    // be replaced rather than edited.
    expect(NotificationChannelSpec.legacyIds, contains('watering_reminders'));
    expect(NotificationChannelSpec.id, isNot('watering_reminders'));
  });

  test('action buttons are attached only when asked for', () {
    expect(
      NotificationChannelSpec.details(withActions: true).android!.actions
          ?.map((a) => a.id),
      ['mark_done', 'snooze'],
    );
    expect(NotificationChannelSpec.details().android!.actions, isNull);
  });

  test('service and background handler share one channel definition', () {
    final fromService = NotificationService.details(withActions: true).android!;
    final fromSpec =
        NotificationChannelSpec.details(withActions: true).android!;

    expect(fromService.channelId, fromSpec.channelId);
    expect(fromService.importance, fromSpec.importance);
    expect(NotificationService.actionMarkDone,
        NotificationChannelSpec.actionMarkDone);
    expect(
        NotificationService.actionSnooze, NotificationChannelSpec.actionSnooze);
  });
}
