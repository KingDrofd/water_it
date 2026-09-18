import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The single definition of the reminder notification channel, shared by the
/// scheduler and the background action handler so the two can never drift.
///
/// Android freezes a channel's importance at creation time - editing these
/// values does nothing on a device that already created the channel. To change
/// how reminders behave, publish a NEW [id] and add the old one to
/// [legacyIds] so it stops cluttering the system settings screen.
class NotificationChannelSpec {
  const NotificationChannelSpec._();

  /// v2: raised to high importance so reminders surface as a heads-up popup
  /// instead of silently landing in the shade.
  static const String id = 'care_reminders_v2';
  static const String name = 'Care reminders';
  static const String description = 'Notifications for plant care reminders.';

  /// Channels from previous versions, deleted on startup.
  static const List<String> legacyIds = ['watering_reminders'];

  static const String actionMarkDone = 'mark_done';
  static const String actionSnooze = 'snooze';

  static const List<AndroidNotificationAction> actions = [
    AndroidNotificationAction(
      actionMarkDone,
      'Mark done',
      showsUserInterface: false,
    ),
    AndroidNotificationAction(
      actionSnooze,
      'Snooze',
      showsUserInterface: false,
    ),
  ];

  /// [withActions] adds the Mark done / Snooze buttons; the daily summary
  /// has no single task to act on, so it opts out.
  static NotificationDetails details({bool withActions = false}) {
    final android = AndroidNotificationDetails(
      id,
      name,
      channelDescription: description,
      // High importance is what makes Android float the notification over
      // the current screen rather than only adding it to the shade.
      importance: Importance.high,
      priority: Priority.high,
      // Stated explicitly rather than relying on library defaults: these are
      // baked into the channel at creation time and cannot be changed later.
      playSound: true,
      enableVibration: true,
      actions: withActions ? actions : null,
    );
    const ios = DarwinNotificationDetails();
    return NotificationDetails(android: android, iOS: ios);
  }

  /// Removes channels published by earlier versions of the app.
  static Future<void> deleteLegacyChannels(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }
    for (final legacyId in legacyIds) {
      try {
        await android.deleteNotificationChannel(legacyId);
      } catch (_) {
        // Channel may not exist on this device; nothing to clean up.
      }
    }
  }
}
