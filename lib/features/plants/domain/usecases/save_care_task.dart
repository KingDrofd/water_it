import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/repositories/care_task_repository.dart';

class SaveCareTask {
  SaveCareTask(this._repository);

  final CareTaskRepository _repository;

  Future<void> call(CareTask task) => _repository.saveTask(task);
}
