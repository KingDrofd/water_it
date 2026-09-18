import 'package:water_it/features/plants/data/datasources/care_task_local_data_source.dart';
import 'package:water_it/features/plants/data/models/care_task_model.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/repositories/care_task_repository.dart';

class CareTaskRepositoryImpl implements CareTaskRepository {
  CareTaskRepositoryImpl(this._localDataSource);

  final CareTaskLocalDataSource _localDataSource;

  @override
  Future<List<CareTask>> getTasksForPlant(String plantId) =>
      _localDataSource.getTasksForPlant(plantId);

  @override
  Future<List<CareTask>> getAllTasks() => _localDataSource.getAllTasks();

  @override
  Future<void> saveTask(CareTask task) =>
      _localDataSource.upsertTask(CareTaskModel.fromEntity(task));

  @override
  Future<void> deleteTask(String id) => _localDataSource.deleteTask(id);
}
