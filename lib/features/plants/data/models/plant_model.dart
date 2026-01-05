import 'dart:convert';

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
    super.scientificName,
    super.imagePaths = const [],
    super.reminders = const [],
  });

  @override
  PlantModel copyWith({
    String? id,
    String? name,
    int? ageMonths,
    String? description,
    String? origin,
    String? soilType,
    String? preferredLighting,
    String? wateringLevel,
    String? scientificName,
    List<String>? imagePaths,
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
                      preferredTime: r.preferredTime,
                      notes: r.notes,
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
      scientificName: scientificName ?? this.scientificName,
      imagePaths: imagePaths ?? this.imagePaths,
      reminders: mappedReminders,
    );
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
      soilType: map['soil_type'] as String?,
      preferredLighting: map['preferred_lighting'] as String?,
      wateringLevel: map['watering_level'] as String?,
      scientificName: map['scientific_name'] as String?,
      imagePaths: decodedImages,
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
      'soil_type': soilType,
      'preferred_lighting': preferredLighting,
      'watering_level': wateringLevel,
      'scientific_name': scientificName,
      'image_paths': jsonEncode(imagePaths),
    };
  }
}

class WateringReminderModel extends WateringReminder {
  const WateringReminderModel({
    required super.id,
    required super.plantId,
    required super.frequencyDays,
    super.preferredTime,
    super.notes,
  });

  factory WateringReminderModel.fromMap(Map<String, dynamic> map) {
    return WateringReminderModel(
      id: map['id'] as String,
      plantId: map['plant_id'] as String,
      frequencyDays: map['frequency_days'] as int,
      preferredTime: map['preferred_time'] != null
          ? DateTime.tryParse(map['preferred_time'] as String)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_id': plantId,
      'frequency_days': frequencyDays,
      'preferred_time': preferredTime?.toIso8601String(),
      'notes': notes,
    };
  }
}
