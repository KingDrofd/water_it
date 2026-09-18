import 'package:water_it/features/plants/domain/entities/care_task.dart';

abstract class CareTaskRepository {
  /// All care tasks for a plant, every type, active or not.
  Future<List<CareTask>> getTasksForPlant(String plantId);

  /// Every care task in the database (used for notification scheduling).
  Future<List<CareTask>> getAllTasks();

  Future<void> saveTask(CareTask task);

  Future<void> deleteTask(String id);
}
