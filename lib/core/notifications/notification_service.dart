import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';

class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Timezone init failed, falling back to UTC: $error');
      }
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  Future<bool> canScheduleExactAlarms() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return true;
    }
    return await android.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmsPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return true;
    }
    return await android.requestExactAlarmsPermission() ?? false;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> scheduleWateringReminders(List<Plant> plants) async {
    await initialize();
    final enabled = await AppSettings.getWateringRemindersEnabled();
    if (!enabled) {
      await cancelAll();
      return;
    }

    await cancelAll();
    final now = DateTime.now();

    for (final plant in plants) {
      for (final reminder in plant.reminders) {
        if (reminder.weekdays.isEmpty) {
          continue;
        }

        final preferred = reminder.preferredTime ??
            DateTime(now.year, now.month, now.day, 9);
        final hour = preferred.hour;
        final minute = preferred.minute;

        for (final weekday in reminder.weekdays) {
          final scheduled = _nextWeekdayOccurrence(
            now,
            weekday: weekday,
            hour: hour,
            minute: minute,
          );
          final id = _notificationId(
            plantId: plant.id,
            reminderId: reminder.id,
            weekday: weekday,
          );

          if (kDebugMode) {
            debugPrint(
              'Schedule reminder: plant=${plant.id} reminder=${reminder.id} '
              'weekday=$weekday local=$scheduled tz=${tz.local.name}',
            );
          }

          await _scheduleWithFallback(
            id: id,
            title: 'Water ${plant.name}',
            body: reminder.notes ?? 'Time to water your plant.',
            scheduled: scheduled,
            matchComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
    }

    await AppSettings.setLastNotificationSchedule(DateTime.now());
  }

  Future<bool> showTestNotification({
    Duration delay = const Duration(seconds: 10),
  }) async {
    await initialize();
    final scheduled = DateTime.now().add(delay);
    if (kDebugMode) {
      debugPrint(
        'Schedule test: local=$scheduled tz=${tz.local.name}',
      );
    }

    try {
      final exact = await _scheduleWithFallback(
        id: 1,
        title: 'Water It',
        body: 'Test notification',
        scheduled: scheduled,
      );
      await AppSettings.setLastNotificationTest(DateTime.now());
      return exact;
    } on PlatformException catch (error) {
      rethrow;
    }
  }

  Future<void> showImmediateTestNotification() async {
    await initialize();
    await _plugin.show(
      2,
      'Water It',
      'Immediate test notification',
      _details(),
    );
    await AppSettings.setLastNotificationTest(DateTime.now());
  }

  Future<int> pendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduled,
    required AndroidScheduleMode mode,
    DateTimeComponents? matchComponents,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      _details(),
      androidAllowWhileIdle: true,
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'watering_reminders',
      'Watering reminders',
      channelDescription: 'Notifications for plant watering reminders.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  int _notificationId({
    required String plantId,
    required String reminderId,
    required int weekday,
  }) {
    final key = '$plantId-$reminderId-$weekday';
    return key.hashCode & 0x7fffffff;
  }

  Future<bool> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required DateTime scheduled,
    DateTimeComponents? matchComponents,
    AndroidScheduleMode fallbackMode = AndroidScheduleMode.inexactAllowWhileIdle,
  }) async {
    final exactAllowed = await canScheduleExactAlarms();
    if (!exactAllowed) {
      await _schedule(
        id: id,
        title: title,
        body: body,
        scheduled: scheduled,
        mode: fallbackMode,
        matchComponents: matchComponents,
      );
      return false;
    }

    try {
      await _schedule(
        id: id,
        title: title,
        body: body,
        scheduled: scheduled,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
        matchComponents: matchComponents,
      );
      return true;
    } on PlatformException catch (error) {
      if (error.code != 'exact_alarms_not_permitted') {
        rethrow;
      }
      if (kDebugMode) {
        debugPrint('Exact alarms not permitted; using inexact schedule.');
      }
      await _schedule(
        id: id,
        title: title,
        body: body,
        scheduled: scheduled,
        mode: fallbackMode,
        matchComponents: matchComponents,
      );
      return false;
    }
  }

  DateTime _nextWeekdayOccurrence(
    DateTime now, {
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    var daysAhead = (weekday - now.weekday) % 7;
    var scheduled = today.add(Duration(days: daysAhead));
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }
    return scheduled;
  }
}
