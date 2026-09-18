import 'package:water_it/core/notifications/notification_payload.dart';

/// One notification to put on the system schedule. Produced by the planner,
/// consumed by [NotificationService.applySchedule].
class ReminderPlan {
  const ReminderPlan({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    this.repeatsWeekly = false,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;

  /// First fire time. With [repeatsWeekly] the notification recurs every
  /// week at this weekday+time; otherwise it fires once.
  final DateTime scheduledAt;
  final bool repeatsWeekly;
  final NotificationPayload payload;
}
