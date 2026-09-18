import 'package:water_it/features/plants/domain/entities/care_event.dart';

class CareEventModel extends CareEvent {
  const CareEventModel({
    required super.id,
    required super.plantId,
    super.taskId,
    super.type,
    required super.completedAt,
    super.note,
    super.source,
  });

  factory CareEventModel.fromEntity(CareEvent event) {
    return event is CareEventModel
        ? event
        : CareEventModel(
            id: event.id,
            plantId: event.plantId,
            taskId: event.taskId,
            type: event.type,
            completedAt: event.completedAt,
            note: event.note,
            source: event.source,
          );
  }

  factory CareEventModel.fromMap(Map<String, dynamic> map) {
    return CareEventModel(
      id: map['id'] as String,
      plantId: map['plant_id'] as String,
      taskId: map['task_id'] as String?,
      type: map['type'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
      note: map['note'] as String?,
      source: CareEventSource.values.firstWhere(
        (s) => s.name == map['source'],
        orElse: () => CareEventSource.detail,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_id': plantId,
      'task_id': taskId,
      'type': type,
      'completed_at': completedAt.toIso8601String(),
      'note': note,
      'source': source.name,
    };
  }
}
