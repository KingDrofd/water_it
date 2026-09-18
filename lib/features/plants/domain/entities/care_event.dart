/// Where a care completion was recorded from.
enum CareEventSource { detail, home, notification }

/// A completed care action for a plant — the unit of the care log.
///
/// [type] matches the `care_tasks.type` vocabulary ('water' today; more task
/// types arrive with the task editor).
class CareEvent {
  const CareEvent({
    required this.id,
    required this.plantId,
    this.taskId,
    this.type = waterType,
    required this.completedAt,
    this.note,
    this.source = CareEventSource.detail,
  });

  static const String waterType = 'water';

  final String id;
  final String plantId;
  final String? taskId;
  final String type;
  final DateTime completedAt;
  final String? note;
  final CareEventSource source;
}
