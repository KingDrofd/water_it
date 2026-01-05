import 'package:water_it/features/plants/domain/entities/plant.dart';

abstract class PlantsRepository {
  Future<List<Plant>> getPlants();
  Future<Plant?> getPlant(String id);
  Future<void> upsertPlant(Plant plant);
  Future<void> deletePlant(String id);
}
