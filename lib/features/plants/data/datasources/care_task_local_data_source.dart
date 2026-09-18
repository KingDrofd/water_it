import 'package:sqflite/sqflite.dart';
import 'package:water_it/features/plants/data/models/care_task_model.dart';

abstract class CareTaskLocalDataSource {
  Future<List<CareTaskModel>> getTasksForPlant(String plantId);
  Future<List<CareTaskModel>> getAllTasks();
  Future<void> upsertTask(CareTaskModel task);
  Future<void> deleteTask(String id);
}

class CareTaskLocalDataSourceImpl implements CareTaskLocalDataSource {
  CareTaskLocalDataSourceImpl(this.db);

  final Database db;

  @override
  Future<List<CareTaskModel>> getTasksForPlant(String plantId) async {
    final rows = await db.query(
      'care_tasks',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'type, id',
    );
    return rows.map(CareTaskModel.fromMap).toList();
  }

  @override
  Future<List<CareTaskModel>> getAllTasks() async {
    final rows = await db.query('care_tasks', orderBy: 'plant_id, type, id');
    return rows.map(CareTaskModel.fromMap).toList();
  }

  @override
  Future<void> upsertTask(CareTaskModel task) async {
    if (task.id.trim().isEmpty || task.plantId.trim().isEmpty) {
      throw ArgumentError('Care task id and plantId are required');
    }
    await db.insert(
      'care_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    await db.delete('care_tasks', where: 'id = ?', whereArgs: [id]);
  }
}
