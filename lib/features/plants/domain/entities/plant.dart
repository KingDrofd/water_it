import 'package:water_it/features/plants/domain/entities/care_profile.dart';

class Plant {
  const Plant({
    required this.id,
    required this.name,
    this.ageMonths,
    this.description,
    this.origin,
    this.soilType,
    this.preferredLighting,
    this.wateringLevel,
    this.careNotes,
    this.scientificName,
    this.roomId,
    this.imagePaths = const [],
    this.useRandomImage = false,
    this.reminders = const [],
  });

  final String id;
  final String name;
  final int? ageMonths;
  final String? description;
  final String? origin;
  final SoilKind? soilType;
  final LightingLevel? preferredLighting;
  final WateringLevel? wateringLevel;
  final String? careNotes;
  final String? scientificName;
  final String? roomId;
  final List<String> imagePaths;
  final bool useRandomImage;
  final List<WateringReminder> reminders;

  Plant copyWith({
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
    return Plant(
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
      reminders: reminders ?? this.reminders,
    );
  }
}

class WateringReminder {
  const WateringReminder({
    required this.id,
    required this.plantId,
    required this.frequencyDays,
    this.weekdays = const [],
    this.preferredTime,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String plantId;
  final int frequencyDays;
  final List<int> weekdays;
  final DateTime? preferredTime;
  final String? notes;

  /// When this reminder was created; due moments before it are not overdue.
  final DateTime? createdAt;
}
