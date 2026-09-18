import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:water_it/core/notifications/notification_action_handler.dart';
import 'package:water_it/core/notifications/notification_channel.dart';
import 'package:water_it/core/notifications/notification_payload.dart';
import 'package:water_it/core/notifications/reminder_plan.dart';
import 'package:water_it/core/settings/app_settings.dart';

/// Invoked when the user taps a reminder body and the payload names a plant.
typedef NotificationPlantTapHandler = void Function(String plantId);

/// Everything that has to be true for a reminder to actually arrive on time.
///
/// Android splits this across two independent OS permissions, so "reminders
/// are on" in the app says nothing about whether they will be delivered.
class NotificationReadiness {
  const NotificationReadiness({
    required this.remindersEnabled,
    required this.notificationsAllowed,
    required this.exactAlarmsAllowed,
    required this.batteryUnrestricted,
  });

  /// The in-app "Watering reminders" preference.
  final bool remindersEnabled;

  /// OS notification permission (POST_NOTIFICATIONS).
  final bool notificationsAllowed;

  /// OS "Alarms & reminders" access (SCHEDULE_EXACT_ALARM). Without it
  /// Android may defer a reminder by hours while the device is dozing.
  final bool exactAlarmsAllowed;

  /// App is exempt from battery optimisation. Without the exemption, Doze and
  /// Battery Saver can defer a reminder until the user next unlocks the phone
  /// - this affects whether it arrives at all, not merely when.
  final bool batteryUnrestricted;

  /// Reminders are on, but the system will suppress them entirely.
  bool get blocked => remindersEnabled && !notificationsAllowed;

  /// Reminders may be delayed indefinitely or missed while the device sleeps.
  bool get batteryRestricted =>
      remindersEnabled && notificationsAllowed && !batteryUnrestricted;

  /// Reminders are delivered, but their timing cannot be trusted.
  bool get imprecise =>
      remindersEnabled && notificationsAllowed && !exactAlarmsAllowed;

  /// Something needs the user's attention for reminders to work properly.
  bool get needsAttention => blocked || batteryRestricted || imprecise;
}

class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String actionMarkDone = NotificationChannelSpec.actionMarkDone;
  static const String actionSnooze = NotificationChannelSpec.actionSnooze;

  /// Set by the app shell to open a plant's detail page on tap.
  static NotificationPlantTapHandler? onPlantTap;

  /// Set by the app shell to refresh UI state after an in-app "Mark done".
  static Future<void> Function()? onActionHandled;

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

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: handleForegroundResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationActionBackground,
    );
    await NotificationChannelSpec.deleteLegacyChannels(_plugin);
    _initialized = true;
  }

  /// Handles taps and action presses while the app process is alive.
  @visibleForTesting
  static Future<void> handleForegroundResponse(
    NotificationResponse response,
  ) async {
    if (response.actionId == actionMarkDone ||
        response.actionId == actionSnooze) {
      await NotificationActionHandler.handle(response);
      await onActionHandled?.call();
      return;
    }
    final payload = NotificationPayload.decode(response.payload);
    if (payload != null && payload.plantId.isNotEmpty) {
      onPlantTap?.call(payload.plantId);
    }
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

  /// Whether the OS currently lets the app post notifications at all.
  Future<bool> areNotificationsAllowed() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return true;
    }
    return await android.areNotificationsEnabled() ?? true;
  }

  /// Whether the app is exempt from battery optimisation.
  Future<bool> isBatteryUnrestricted() async {
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      // Unsupported platform - don't claim a problem we can't verify.
      return true;
    }
  }

  /// Shows Android's own battery-exemption dialog. Callers must explain why
  /// first: Play requires this to be a deliberate, informed user action.
  Future<bool> requestBatteryExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Current delivery readiness, combining the app preference with every OS
  /// restriction that can stop a reminder reaching the user.
  Future<NotificationReadiness> readiness() async {
    await initialize();
    return NotificationReadiness(
      remindersEnabled: await AppSettings.getWateringRemindersEnabled(),
      notificationsAllowed: await areNotificationsAllowed(),
      exactAlarmsAllowed: await canScheduleExactAlarms(),
      batteryUnrestricted: await isBatteryUnrestricted(),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Replaces the entire system schedule with [plans]. The scheduler owns
  /// what to schedule; this just puts it on the system.
  Future<void> applySchedule(List<ReminderPlan> plans) async {
    await initialize();
    await cancelAll();

    for (final plan in plans) {
      final isSummary =
          plan.payload.type == NotificationPayload.summaryType;
      if (kDebugMode) {
        debugPrint(
          'Schedule: id=${plan.id} "${plan.title}" at=${plan.scheduledAt} '
          'weekly=${plan.repeatsWeekly} tz=${tz.local.name}',
        );
      }
      await _scheduleWithFallback(
        id: plan.id,
        title: plan.title,
        body: plan.body,
        scheduled: plan.scheduledAt,
        matchComponents:
            plan.repeatsWeekly ? DateTimeComponents.dayOfWeekAndTime : null,
        payload: plan.payload.encode(),
        withActions: !isSummary,
      );
    }
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

    final exact = await _scheduleWithFallback(
      id: 1,
      title: 'Water It',
      body: 'Test notification',
      scheduled: scheduled,
    );
    await AppSettings.setLastNotificationTest(DateTime.now());
    return exact;
  }

  Future<void> showImmediateTestNotification() async {
    await initialize();
    await _plugin.show(
      2,
      'Water It',
      'Immediate test notification',
      details(),
    );
    await AppSettings.setLastNotificationTest(DateTime.now());
  }

  Future<int> pendingCount() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  /// Whether (and how) a notification launched the app from a dead state.
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    await initialize();
    return _plugin.getNotificationAppLaunchDetails();
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduled,
    required AndroidScheduleMode mode,
    DateTimeComponents? matchComponents,
    String? payload,
    bool withActions = false,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      details(withActions: withActions),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
      payload: payload,
    );
  }

  static NotificationDetails details({bool withActions = false}) =>
      NotificationChannelSpec.details(withActions: withActions);

  Future<bool> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required DateTime scheduled,
    DateTimeComponents? matchComponents,
    String? payload,
    bool withActions = false,
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
        payload: payload,
        withActions: withActions,
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
        payload: payload,
        withActions: withActions,
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
        payload: payload,
        withActions: withActions,
      );
      return false;
    }
  }
}
