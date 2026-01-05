import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';

class DeletePlant {
  DeletePlant(this._repository);

  final PlantsRepository _repository;

  Future<void> call(String id) {
    return _repository.deletePlant(id);
  }
}
