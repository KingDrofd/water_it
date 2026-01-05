import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';

class GetPlant {
  GetPlant(this._repository);

  final PlantsRepository _repository;

  Future<Plant?> call(String id) {
    return _repository.getPlant(id);
  }
}
