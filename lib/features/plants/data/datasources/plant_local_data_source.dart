import 'package:sqflite/sqflite.dart';
import 'package:water_it/features/plants/data/models/plant_model.dart';

abstract class PlantLocalDataSource {
  Future<List<PlantModel>> getPlants();
  Future<PlantModel?> getPlant(String id);
  Future<void> upsertPlant(PlantModel plant);
  Future<void> deletePlant(String id);
}

class PlantLocalDataSourceImpl implements PlantLocalDataSource {
  PlantLocalDataSourceImpl(this.db);

  final Database db;

  static const createPlantTable = '''
CREATE TABLE IF NOT EXISTS plants(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  age_months INTEGER,
  description TEXT,
  origin TEXT,
  soil_type TEXT,
  preferred_lighting TEXT,
  watering_level TEXT,
  scientific_name TEXT,
  image_paths TEXT
);
''';

  static const createReminderTable = '''
CREATE TABLE IF NOT EXISTS watering_reminders(
  id TEXT PRIMARY KEY,
  plant_id TEXT NOT NULL,
  frequency_days INTEGER NOT NULL,
  preferred_time TEXT,
  notes TEXT,
  FOREIGN KEY(plant_id) REFERENCES plants(id) ON DELETE CASCADE
);
''';

  @override
  Future<List<PlantModel>> getPlants() async {
    final plantRows = await db.query('plants');
    final reminderRows = await db.query('watering_reminders');

    return plantRows.map((plantRow) {
      final reminders = reminderRows
          .where((r) => r['plant_id'] == plantRow['id'])
          .map(WateringReminderModel.fromMap)
          .toList();
      return PlantModel.fromMap(plantRow, reminders: reminders);
    }).toList();
  }

  @override
  Future<PlantModel?> getPlant(String id) async {
    final plantRows =
        await db.query('plants', where: 'id = ?', whereArgs: [id], limit: 1);
    if (plantRows.isEmpty) return null;

    final reminderRows = await db.query(
      'watering_reminders',
      where: 'plant_id = ?',
      whereArgs: [id],
    );

    final reminders =
        reminderRows.map(WateringReminderModel.fromMap).toList();
    return PlantModel.fromMap(plantRows.first, reminders: reminders);
  }

  @override
  Future<void> upsertPlant(PlantModel plant) async {
    _validatePlant(plant);

    await db.transaction((txn) async {
      await txn.insert(
        'plants',
        plant.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'watering_reminders',
        where: 'plant_id = ?',
        whereArgs: [plant.id],
      );

      for (final reminder in plant.reminders) {
        final reminderModel = reminder is WateringReminderModel
            ? reminder
            : WateringReminderModel(
                id: reminder.id,
                plantId: reminder.plantId,
                frequencyDays: reminder.frequencyDays,
                preferredTime: reminder.preferredTime,
                notes: reminder.notes,
              );
        await txn.insert(
          'watering_reminders',
          reminderModel.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> deletePlant(String id) async {
    await db.transaction((txn) async {
      await txn.delete(
        'watering_reminders',
        where: 'plant_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'plants',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  void _validatePlant(PlantModel plant) {
    if (plant.id.trim().isEmpty || plant.name.trim().isEmpty) {
      throw ArgumentError('Plant id and name are required');
    }

    for (final reminder in plant.reminders) {
      if (reminder.id.trim().isEmpty) {
        throw ArgumentError('Reminder id is required');
      }
      if (reminder.frequencyDays <= 0) {
        throw ArgumentError('Reminder frequency must be positive');
      }
    }
  }
}
