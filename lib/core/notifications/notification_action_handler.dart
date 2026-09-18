import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import 'package:water_it/core/database/app_database.dart';
import 'package:water_it/core/notifications/notification_channel.dart';
import 'package:water_it/core/notifications/notification_payload.dart';
import 'package:water_it/features/plants/domain/services/reminder_planner.dart';

/// Background entry point for notification action buttons. Runs in its own
/// isolate when the app process isn't alive, so everything it needs is set
/// up from scratch here.
@pragma('vm:entry-point')
Future<void> notificationActionBackground(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await NotificationActionHandler.handle(response);
}

/// Handles "Mark done" and "Snooze" from a reminder notification. Isolate
/// agnostic: used by both the background entry point and the foreground
/// response callback.
class NotificationActionHandler {
  const NotificationActionHandler._();

  static const Uuid _uuid = Uuid();

  /// Snoozed one-shots get their own id so they never overwrite the
  /// original (possibly weekly-recurring) notification.
  static int snoozeId(int originalId) => originalId | 0x40000000;

  static Future<void> handle(NotificationResponse response) async {
    final payload = NotificationPayload.decode(response.payload);
    if (payload == null || payload.type == NotificationPayload.summaryType) {
      return;
    }

    try {
      switch (response.actionId) {
        case NotificationChannelSpec.actionMarkDone:
          await _markDone(response, payload);
        case NotificationChannelSpec.actionSnooze:
          await _snooze(response, payload);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Notification action failed: $error');
      }
    }
  }

  static Future<void> _markDone(
    NotificationResponse response,
    NotificationPayload payload,
  ) async {
    if (payload.plantId.isEmpty) {
      return;
    }
    final now = DateTime.now();

    // Log the care event straight into the database — the app may not be
    // running, so this can't go through the repository layer / DI.
    final db = await AppDatabase.open();
    await db.insert('care_events', {
      'id': _uuid.v4(),
      'plant_id': payload.plantId,
      'task_id': payload.taskId,
      'type': payload.type,
      'completed_at': now.toIso8601String(),
      'note': null,
      'source': 'notification',
    });

    final plugin = FlutterLocalNotificationsPlugin();
    if (response.id != null) {
      await plugin.cancel(response.id!);
    }

    // Interval tasks re-anchor on completion: next reminder is N days from
    // now. (Weekly recurrences keep firing on their weekdays untouched.)
    final taskId = payload.taskId;
    if (payload.intervalDays > 0 && taskId != null) {
      await _initTimezone();
      final next = ReminderPlanner.nextIntervalOccurrence(
        anchor: now,
        intervalDays: payload.intervalDays,
        hour: payload.hour,
        minute: payload.minute,
        now: now,
      );
      await plugin.zonedSchedule(
        ReminderPlanner.notificationId('$taskId-interval'),
        payload.title,
        payload.body,
        tz.TZDateTime.from(next, tz.local),
        _actionDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload.encode(),
      );
    }
  }

  static Future<void> _snooze(
    NotificationResponse response,
    NotificationPayload payload,
  ) async {
    final plugin = FlutterLocalNotificationsPlugin();
    if (response.id != null) {
      await plugin.cancel(response.id!);
    }

    await _initTimezone();
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
      payload.hour,
      payload.minute,
    ).add(const Duration(days: 1));

    await plugin.zonedSchedule(
      snoozeId(response.id ?? payload.hashCode & 0x7fffffff),
      payload.title,
      payload.body,
      tz.TZDateTime.from(tomorrow, tz.local),
      _actionDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload.encode(),
    );
  }

  static NotificationDetails _actionDetails() =>
      NotificationChannelSpec.details(withActions: true);

  static Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
