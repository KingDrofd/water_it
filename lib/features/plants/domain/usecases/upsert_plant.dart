import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';

class UpsertPlant {
  UpsertPlant(this._repository);

  final PlantsRepository _repository;

  Future<void> call(Plant plant) {
    return _repository.upsertPlant(plant);
  }
}
