/// The six care task kinds from the Care System spec. Watering stays the
/// default; `custom` uses [CareTask.customLabel] for its display name.
enum CareTaskType { water, fertilize, mist, repot, prune, custom }

/// How a task's due moments are produced: fixed weekdays or a rolling
/// every-N-days interval anchored on the last completion.
enum CareScheduleType { weekly, interval }

class CareTask {
  const CareTask({
    required this.id,
    required this.plantId,
    this.type = CareTaskType.water,
    this.customLabel,
    this.scheduleType = CareScheduleType.weekly,
    this.weekdays = const [],
    this.intervalDays = 0,
    this.preferredTime,
    this.notes,
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String plantId;
  final CareTaskType type;
  final String? customLabel;
  final CareScheduleType scheduleType;

  /// 1=Mon..7=Sun; meaningful for [CareScheduleType.weekly].
  final List<int> weekdays;

  /// Meaningful for [CareScheduleType.interval].
  final int intervalDays;
  final DateTime? preferredTime;
  final String? notes;
  final bool active;

  /// When the task was first saved. Due moments before this never count as
  /// overdue - a task cannot have been missed before it existed.
  final DateTime? createdAt;

  /// Display name: the type name, or the custom label when set.
  String get label {
    if (type == CareTaskType.custom) {
      final custom = customLabel?.trim();
      return custom == null || custom.isEmpty ? 'Custom task' : custom;
    }
    final name = type.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  CareTask copyWith({
    String? id,
    String? plantId,
    CareTaskType? type,
    String? customLabel,
    CareScheduleType? scheduleType,
    List<int>? weekdays,
    int? intervalDays,
    DateTime? preferredTime,
    String? notes,
    bool? active,
    DateTime? createdAt,
  }) {
    return CareTask(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      type: type ?? this.type,
      customLabel: customLabel ?? this.customLabel,
      scheduleType: scheduleType ?? this.scheduleType,
      weekdays: weekdays ?? this.weekdays,
      intervalDays: intervalDays ?? this.intervalDays,
      preferredTime: preferredTime ?? this.preferredTime,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
