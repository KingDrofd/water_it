import 'package:sqflite/sqflite.dart';
import 'package:water_it/features/plants/data/models/care_event_model.dart';

abstract class CareEventLocalDataSource {
  Future<void> insertEvent(CareEventModel event);
  Future<List<CareEventModel>> getEventsForPlant(String plantId);

  /// Latest `completed_at` per plant per type: plantId -> type -> timestamp.
  Future<Map<String, Map<String, DateTime>>> getLatestByPlantAndType();
}

class CareEventLocalDataSourceImpl implements CareEventLocalDataSource {
  CareEventLocalDataSourceImpl(this.db);

  final Database db;

  @override
  Future<void> insertEvent(CareEventModel event) async {
    if (event.id.trim().isEmpty ||
        event.plantId.trim().isEmpty ||
        event.type.trim().isEmpty) {
      throw ArgumentError('Care event id, plantId, and type are required');
    }
    await db.insert(
      'care_events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<CareEventModel>> getEventsForPlant(String plantId) async {
    final rows = await db.query(
      'care_events',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'completed_at DESC',
    );
    return rows.map(CareEventModel.fromMap).toList();
  }

  @override
  Future<Map<String, Map<String, DateTime>>> getLatestByPlantAndType() async {
    final rows = await db.rawQuery(
      'SELECT plant_id, type, MAX(completed_at) AS latest '
      'FROM care_events GROUP BY plant_id, type',
    );
    final result = <String, Map<String, DateTime>>{};
    for (final row in rows) {
      final latest = row['latest'] as String?;
      if (latest == null) continue;
      final parsed = DateTime.tryParse(latest);
      if (parsed == null) continue;
      result.putIfAbsent(row['plant_id'] as String, () => {})[
          row['type'] as String] = parsed;
    }
    return result;
  }
}
