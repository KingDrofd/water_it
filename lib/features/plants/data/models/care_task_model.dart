import 'dart:convert';

import 'package:water_it/features/plants/domain/entities/care_task.dart';

class CareTaskModel extends CareTask {
  const CareTaskModel({
    required super.id,
    required super.plantId,
    super.type,
    super.customLabel,
    super.scheduleType,
    super.weekdays,
    super.intervalDays,
    super.preferredTime,
    super.notes,
    super.active,
    super.createdAt,
  });

  factory CareTaskModel.fromEntity(CareTask task) {
    return CareTaskModel(
      id: task.id,
      plantId: task.plantId,
      type: task.type,
      customLabel: task.customLabel,
      scheduleType: task.scheduleType,
      weekdays: task.weekdays,
      intervalDays: task.intervalDays,
      preferredTime: task.preferredTime,
      notes: task.notes,
      active: task.active,
      createdAt: task.createdAt,
    );
  }

  factory CareTaskModel.fromMap(Map<String, dynamic> map) {
    final weekdaysJson = map['weekdays'] as String?;
    final decodedWeekdays = weekdaysJson == null || weekdaysJson.isEmpty
        ? <int>[]
        : List<int>.from(jsonDecode(weekdaysJson) as List<dynamic>);

    return CareTaskModel(
      id: map['id'] as String,
      plantId: map['plant_id'] as String,
      type: CareTaskType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => CareTaskType.custom,
      ),
      customLabel: map['custom_label'] as String?,
      scheduleType: map['schedule_type'] == 'interval'
          ? CareScheduleType.interval
          : CareScheduleType.weekly,
      weekdays: decodedWeekdays,
      intervalDays: map['interval_days'] as int? ?? 0,
      preferredTime: map['preferred_time'] != null
          ? DateTime.tryParse(map['preferred_time'] as String)
          : null,
      notes: map['notes'] as String?,
      active: (map['active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_id': plantId,
      'type': type.name,
      'custom_label': customLabel,
      'schedule_type': scheduleType.name,
      'weekdays': jsonEncode(weekdays),
      'interval_days': intervalDays,
      'preferred_time': preferredTime?.toIso8601String(),
      'notes': notes,
      'active': active ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
