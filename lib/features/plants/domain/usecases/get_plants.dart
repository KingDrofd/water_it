import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';

class GetPlants {
  GetPlants(this._repository);

  final PlantsRepository _repository;

  Future<List<Plant>> call() {
    return _repository.getPlants();
  }
}
