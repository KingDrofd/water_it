import 'dart:convert';

import 'package:water_it/features/plants/domain/entities/care_profile.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';

class PlantModel extends Plant {
  const PlantModel({
    required super.id,
    required super.name,
    super.ageMonths,
    super.description,
    super.origin,
    super.soilType,
    super.preferredLighting,
    super.wateringLevel,
    super.careNotes,
    super.scientificName,
    super.roomId,
    super.imagePaths = const [],
    super.useRandomImage = false,
    super.reminders = const [],
  });

  @override
  PlantModel copyWith({
    String? id,
    String? name,
    int? ageMonths,
    String? description,
    String? origin,
    SoilKind? soilType,
    LightingLevel? preferredLighting,
    WateringLevel? wateringLevel,
    String? careNotes,
    String? scientificName,
    String? roomId,
    List<String>? imagePaths,
    bool? useRandomImage,
    List<WateringReminder>? reminders,
  }) {
    final mappedReminders = reminders != null
        ? reminders
            .map(
              (r) => r is WateringReminderModel
                  ? r
                  : WateringReminderModel(
                      id: r.id,
                      plantId: r.plantId,
                      frequencyDays: r.frequencyDays,
                      weekdays: r.weekdays,
                      preferredTime: r.preferredTime,
                      notes: r.notes,
                      createdAt: r.createdAt,
                    ),
            )
            .toList()
        : this.reminders.cast<WateringReminderModel>();

    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ageMonths: ageMonths ?? this.ageMonths,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      soilType: soilType ?? this.soilType,
      preferredLighting: preferredLighting ?? this.preferredLighting,
      wateringLevel: wateringLevel ?? this.wateringLevel,
      careNotes: careNotes ?? this.careNotes,
      scientificName: scientificName ?? this.scientificName,
      roomId: roomId ?? this.roomId,
      imagePaths: imagePaths ?? this.imagePaths,
      useRandomImage: useRandomImage ?? this.useRandomImage,
      reminders: mappedReminders,
    );
  }

  static T? _enumFromName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String || name.isEmpty) {
      return null;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return null;
  }

  factory PlantModel.fromMap(
    Map<String, dynamic> map, {
    List<WateringReminderModel> reminders = const [],
  }) {
    final imagesJson = map['image_paths'] as String?;
    final decodedImages = imagesJson == null || imagesJson.isEmpty
        ? <String>[]
        : List<String>.from(jsonDecode(imagesJson) as List<dynamic>);

    return PlantModel(
      id: map['id'] as String,
      name: map['name'] as String,
      ageMonths: map['age_months'] as int?,
      description: map['description'] as String?,
      origin: map['origin'] as String?,
      soilType: _enumFromName(SoilKind.values, map['soil_type']),
      preferredLighting:
          _enumFromName(LightingLevel.values, map['preferred_lighting']),
      wateringLevel: _enumFromName(WateringLevel.values, map['watering_level']),
      careNotes: map['care_notes'] as String?,
      scientificName: map['scientific_name'] as String?,
      roomId: map['room_id'] as String?,
      imagePaths: decodedImages,
      useRandomImage: (map['use_random_image'] as int? ?? 0) == 1,
      reminders: reminders,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age_months': ageMonths,
      'description': description,
      'origin': origin,
      'soil_type': soilType?.name,
      'preferred_lighting': preferredLighting?.name,
      'watering_level': wateringLevel?.name,
      'care_notes': careNotes,
      'scientific_name': scientificName,
      'room_id': roomId,
      'image_paths': jsonEncode(imagePaths),
      'use_random_image': useRandomImage ? 1 : 0,
    };
  }
}

class WateringReminderModel extends WateringReminder {
  const WateringReminderModel({
    required super.id,
    required super.plantId,
    required super.frequencyDays,
    super.weekdays = const [],
    super.preferredTime,
    super.notes,
    super.createdAt,
  });

  /// Builds a reminder from a `care_tasks` row of type 'water'.
  factory WateringReminderModel.fromCareTaskMap(Map<String, dynamic> map) {
    final weekdaysJson = map['weekdays'] as String?;
    final decodedWeekdays = weekdaysJson == null || weekdaysJson.isEmpty
        ? <int>[]
        : List<int>.from(jsonDecode(weekdaysJson) as List<dynamic>);
    final intervalDays = map['interval_days'] as int? ?? 0;

    return WateringReminderModel(
      id: map['id'] as String,
      plantId: map['plant_id'] as String,
      frequencyDays: intervalDays > 0 ? intervalDays : 7,
      weekdays: decodedWeekdays,
      preferredTime: map['preferred_time'] != null
          ? DateTime.tryParse(map['preferred_time'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  /// Serializes this reminder as a `care_tasks` row of type 'water'.
  Map<String, dynamic> toCareTaskMap() {
    return {
      'id': id,
      'plant_id': plantId,
      'type': 'water',
      'custom_label': null,
      'schedule_type': weekdays.isNotEmpty ? 'weekly' : 'interval',
      'weekdays': jsonEncode(weekdays),
      'interval_days': frequencyDays,
      'preferred_time': preferredTime?.toIso8601String(),
      'notes': notes,
      'active': 1,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
