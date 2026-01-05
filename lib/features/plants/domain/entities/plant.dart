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
    this.scientificName,
    this.imagePaths = const [],
    this.reminders = const [],
  });

  final String id;
  final String name;
  final int? ageMonths;
  final String? description;
  final String? origin;
  final String? soilType;
  final String? preferredLighting;
  final String? wateringLevel;
  final String? scientificName;
  final List<String> imagePaths;
  final List<WateringReminder> reminders;

  Plant copyWith({
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
    return Plant(
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
      reminders: reminders ?? this.reminders,
    );
  }
}

class WateringReminder {
  const WateringReminder({
    required this.id,
    required this.plantId,
    required this.frequencyDays,
    this.preferredTime,
    this.notes,
  });

  final String id;
  final String plantId;
  final int frequencyDays;
  final DateTime? preferredTime;
  final String? notes;
}

