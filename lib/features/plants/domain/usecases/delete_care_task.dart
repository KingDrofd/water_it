import 'package:water_it/features/plants/domain/repositories/care_task_repository.dart';

class DeleteCareTask {
  DeleteCareTask(this._repository);

  final CareTaskRepository _repository;

  Future<void> call(String id) => _repository.deleteTask(id);
}
