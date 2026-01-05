import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';
import 'package:water_it/features/plants/data/models/plant_model.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';

class PlantsRepositoryImpl implements PlantsRepository {
  PlantsRepositoryImpl(this._localDataSource);

  final PlantLocalDataSource _localDataSource;

  @override
  Future<List<Plant>> getPlants() {
    return _localDataSource.getPlants();
  }

  @override
  Future<Plant?> getPlant(String id) {
    return _localDataSource.getPlant(id);
  }

  @override
  Future<void> upsertPlant(Plant plant) {
    final model = plant is PlantModel
        ? plant
        : PlantModel(
            id: plant.id,
            name: plant.name,
            ageMonths: plant.ageMonths,
            description: plant.description,
            origin: plant.origin,
            soilType: plant.soilType,
            preferredLighting: plant.preferredLighting,
            wateringLevel: plant.wateringLevel,
            scientificName: plant.scientificName,
            imagePaths: plant.imagePaths,
            reminders: plant.reminders,
          );
    return _localDataSource.upsertPlant(model);
  }

  @override
  Future<void> deletePlant(String id) {
    return _localDataSource.deletePlant(id);
  }
}
