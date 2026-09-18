import 'package:sqflite/sqflite.dart';
import 'package:water_it/features/plants/data/models/plant_model.dart';

abstract class PlantLocalDataSource {
  Future<List<PlantModel>> getPlants();
  Future<PlantModel?> getPlant(String id);
  Future<void> upsertPlant(PlantModel plant);
  Future<void> deletePlant(String id);
}

/// Persists plants against schema v4: watering reminders are stored as
/// `care_tasks` rows with type 'water'. Rows of other task types are left
/// untouched by this data source (they belong to the care system).
class PlantLocalDataSourceImpl implements PlantLocalDataSource {
  PlantLocalDataSourceImpl(this.db);

  final Database db;

  static const String waterTaskType = 'water';

  @override
  Future<List<PlantModel>> getPlants() async {
    final plantRows = await db.query('plants');
    final taskRows = await db.query(
      'care_tasks',
      where: 'type = ?',
      whereArgs: [waterTaskType],
    );

    return plantRows.map((plantRow) {
      final reminders = taskRows
          .where((r) => r['plant_id'] == plantRow['id'])
          .map(WateringReminderModel.fromCareTaskMap)
          .toList();
      return PlantModel.fromMap(plantRow, reminders: reminders);
    }).toList();
  }

  @override
  Future<PlantModel?> getPlant(String id) async {
    final plantRows =
        await db.query('plants', where: 'id = ?', whereArgs: [id], limit: 1);
    if (plantRows.isEmpty) return null;

    final taskRows = await db.query(
      'care_tasks',
      where: 'plant_id = ? AND type = ?',
      whereArgs: [id, waterTaskType],
    );

    final reminders =
        taskRows.map(WateringReminderModel.fromCareTaskMap).toList();
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
        'care_tasks',
        where: 'plant_id = ? AND type = ?',
        whereArgs: [plant.id, waterTaskType],
      );

      for (final reminder in plant.reminders) {
        final reminderModel = reminder is WateringReminderModel
            ? reminder
            : WateringReminderModel(
                id: reminder.id,
                plantId: reminder.plantId,
                frequencyDays: reminder.frequencyDays,
                weekdays: reminder.weekdays,
                preferredTime: reminder.preferredTime,
                notes: reminder.notes,
                createdAt: reminder.createdAt,
              );
        await txn.insert(
          'care_tasks',
          reminderModel.toCareTaskMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> deletePlant(String id) async {
    await db.transaction((txn) async {
      await txn.delete(
        'care_events',
        where: 'plant_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'care_tasks',
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
