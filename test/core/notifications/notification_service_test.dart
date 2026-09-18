import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:water_it/core/notifications/notification_payload.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/notifications/reminder_plan.dart';

class MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPlugin plugin;
  late NotificationService service;

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
    registerFallbackValue(tz.TZDateTime.now(tz.UTC));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(AndroidScheduleMode.exact);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
  });

  setUp(() {
    plugin = MockPlugin();
    when(() => plugin.initialize(
          any(),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
          onDidReceiveBackgroundNotificationResponse:
              any(named: 'onDidReceiveBackgroundNotificationResponse'),
        )).thenAnswer((_) async => true);
    when(() => plugin.cancelAll()).thenAnswer((_) async {});
    when(() => plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()).thenReturn(null);
    when(() => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
    service = NotificationService(plugin);
  });

  ReminderPlan plan({
    required int id,
    bool weekly = false,
    String type = 'water',
  }) {
    return ReminderPlan(
      id: id,
      title: 'Water Monstera',
      body: 'Time to water your plant.',
      scheduledAt: DateTime(2026, 8, 10, 9),
      repeatsWeekly: weekly,
      payload: NotificationPayload(
        plantId: 'p1',
        taskId: 't1',
        type: type,
        title: 'Water Monstera',
        body: 'Time to water your plant.',
      ),
    );
  }

  test('applySchedule clears the old schedule and schedules every plan',
      () async {
    await service.applySchedule([
      plan(id: 10, weekly: true),
      plan(id: 11),
    ]);

    verify(() => plugin.cancelAll()).called(1);
    verify(() => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        )).called(2);
  });

  test('weekly plans repeat on day-of-week; one-shots do not', () async {
    await service.applySchedule([plan(id: 10, weekly: true)]);

    verify(() => plugin.zonedSchedule(
          10,
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: any(named: 'payload'),
        )).called(1);
  });

  test('plans carry their payload to the platform schedule', () async {
    final p = plan(id: 12);
    await service.applySchedule([p]);

    verify(() => plugin.zonedSchedule(
          12,
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: p.payload.encode(),
        )).called(1);
  });

  test('reminder details expose Mark done and Snooze actions', () {
    final details = NotificationService.details(withActions: true);
    final actions = details.android!.actions!;

    expect(actions.map((a) => a.id).toList(), ['mark_done', 'snooze']);

    final plain = NotificationService.details();
    expect(plain.android!.actions, isNull);
  });
}
