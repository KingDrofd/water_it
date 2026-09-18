import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/repositories/care_task_repository.dart';

class GetCareTasks {
  GetCareTasks(this._repository);

  final CareTaskRepository _repository;

  Future<List<CareTask>> call(String plantId) =>
      _repository.getTasksForPlant(plantId);
}
