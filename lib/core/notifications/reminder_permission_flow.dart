import 'package:flutter/material.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/features/plants/domain/services/reminder_scheduler.dart';

/// One place that explains Android's reminder permissions and walks the user
/// to the right system screen.
///
/// Android needs two separate grants before a reminder arrives on time:
/// notifications (POST_NOTIFICATIONS) and "Alarms & reminders"
/// (SCHEDULE_EXACT_ALARM). The second one is never granted automatically and
/// is buried in system settings, so the app has to ask for it explicitly
/// instead of silently degrading to delayed delivery.
class ReminderPermissionFlow {
  const ReminderPermissionFlow._();

  /// PARKED while we evaluate whether this prompt earns its friction.
  ///
  /// Android still *delivers* reminders without "Alarms & reminders" - the
  /// permission only guarantees their timing (without it the OS may batch
  /// them while dozing). The original "no notifications at all" report turned
  /// out to be the R8/Gson crash, not this permission, so the nagging is
  /// probably not warranted. Flip to true to restore the onboarding ask, the
  /// home banner, and the Settings action in one move.
  static const bool exactAlarmPromptsEnabled = false;

  /// Explains why precise timing is needed, then sends the user to the
  /// system screen that grants it. Returns true once the permission is
  /// actually held.
  static Future<bool> requestExactAlarms(BuildContext context) async {
    final service = getIt<NotificationService>();
    if (await service.canScheduleExactAlarms()) {
      return true;
    }
    if (!exactAlarmPromptsEnabled) {
      return false;
    }
    if (!context.mounted) {
      return false;
    }

    final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Let reminders arrive on time'),
            content: const Text(
              'Android needs the "Alarms & reminders" permission to deliver '
              'reminders at the time you picked. Without it your reminders '
              'still arrive, but can be hours late.\n\n'
              'The next screen is an Android settings page — turn on '
              '"Allow setting alarms and reminders", then come back.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Open settings'),
              ),
            ],
          ),
        ) ??
        false;
    if (!proceed) {
      return false;
    }

    await service.requestExactAlarmsPermission();
    // The user returns from a system screen, so re-read the real state
    // rather than trusting the request's return value.
    final granted = await service.canScheduleExactAlarms();
    if (granted) {
      await _reschedule();
    }
    return granted;
  }

  /// Explains why battery optimisation blocks reminders, then shows
  /// Android's exemption dialog.
  ///
  /// Play allows this permission for reminder apps provided the request is a
  /// deliberate, informed user action - hence the explainer first, and why
  /// this is never triggered during onboarding.
  static Future<bool> requestBatteryExemption(BuildContext context) async {
    final service = getIt<NotificationService>();
    if (await service.isBatteryUnrestricted()) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }

    final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Keep reminders running'),
            content: const Text(
              'To save power, Android can pause background activity for apps '
              'it thinks you are not using. When that happens your reminders '
              'may not arrive until you next unlock your phone.\n\n'
              'Allowing Water It to ignore battery optimisation lets reminders '
              'through. It does not keep your phone awake - reminders are '
              'scheduled by Android itself.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
    if (!proceed) {
      return false;
    }

    final granted = await service.requestBatteryExemption();
    if (granted) {
      await _reschedule();
    }
    return granted;
  }

  /// Some manufacturers ignore the standard exemption and need their own
  /// per-app setting, which no API can reach.
  static Future<void> showManufacturerHelp(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Still not arriving?'),
        content: const SingleChildScrollView(
          child: Text(
            'Some phone makers add their own battery rules on top of '
            "Android's, which no app can change directly:\n\n"
            '- Samsung: Settings > Battery > Background usage limits - remove '
            'Water It from "Sleeping apps" and "Deep sleeping apps", or add '
            'it to "Never sleeping apps".\n'
            '- Xiaomi / Redmi / POCO: App info > Battery saver > No '
            'restrictions, and enable Autostart.\n'
            '- Oppo / realme / OnePlus: App info > Battery > Allow background '
            'activity.\n\n'
            'Turning off the phone-wide Battery Saver also restores normal '
            'delivery.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Re-checks permissions after the app returns to the foreground and
  /// rebuilds the schedule if precise timing just became available.
  static Future<void> refreshAfterResume() async {
    final service = getIt<NotificationService>();
    final readiness = await service.readiness();
    if (readiness.remindersEnabled && readiness.notificationsAllowed) {
      await _reschedule();
    }
  }

  static Future<void> _reschedule() async {
    try {
      await getIt<ReminderScheduler>().rescheduleAll();
    } catch (_) {
      // Scheduling is retried on the next plant load; never block the UI.
    }
  }
}
