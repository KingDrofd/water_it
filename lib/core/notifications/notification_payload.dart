import 'dart:convert';

/// What a scheduled notification carries so its actions can be handled
/// without the app running: which plant/task it belongs to and enough
/// content to re-issue itself (snooze).
class NotificationPayload {
  const NotificationPayload({
    required this.plantId,
    this.taskId,
    required this.type,
    required this.title,
    required this.body,
    this.hour = 9,
    this.minute = 0,
    this.intervalDays = 0,
  });

  /// Payload type marker for the daily summary (no plant/task).
  static const String summaryType = 'summary';

  final String plantId;
  final String? taskId;

  /// Care task type name ('water', 'fertilize', ...) or [summaryType].
  final String type;
  final String title;
  final String body;
  final int hour;
  final int minute;

  /// Interval length for interval-scheduled tasks; 0 for weekly tasks.
  /// Lets the background handler re-anchor without a DB read.
  final int intervalDays;

  String encode() => jsonEncode({
        'plantId': plantId,
        'taskId': taskId,
        'type': type,
        'title': title,
        'body': body,
        'hour': hour,
        'minute': minute,
        'intervalDays': intervalDays,
      });

  static NotificationPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationPayload(
        plantId: map['plantId'] as String? ?? '',
        taskId: map['taskId'] as String?,
        type: map['type'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        hour: map['hour'] as int? ?? 9,
        minute: map['minute'] as int? ?? 0,
        intervalDays: map['intervalDays'] as int? ?? 0,
      );
    } on FormatException {
      return null;
    }
  }
}
