import 'package:water_it/features/plants/data/datasources/plant_image_store.dart';
import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';
import 'package:water_it/features/plants/data/models/plant_model.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';

class PlantsRepositoryImpl implements PlantsRepository {
  PlantsRepositoryImpl(this._localDataSource, this._imageStore);

  final PlantLocalDataSource _localDataSource;
  final PlantImageStore _imageStore;

  @override
  Future<List<Plant>> getPlants() {
    return _localDataSource.getPlants();
  }

  @override
  Future<Plant?> getPlant(String id) {
    return _localDataSource.getPlant(id);
  }

  @override
  Future<void> upsertPlant(Plant plant) async {
    final imagePaths =
        await _imageStore.persistImages(plant.id, plant.imagePaths);
    final model = PlantModel(
      id: plant.id,
      name: plant.name,
      ageMonths: plant.ageMonths,
      description: plant.description,
      origin: plant.origin,
      soilType: plant.soilType,
      preferredLighting: plant.preferredLighting,
      wateringLevel: plant.wateringLevel,
      careNotes: plant.careNotes,
      scientificName: plant.scientificName,
      roomId: plant.roomId,
      imagePaths: imagePaths,
      useRandomImage: plant.useRandomImage,
      reminders: plant.reminders,
    );
    return _localDataSource.upsertPlant(model);
  }

  @override
  Future<void> deletePlant(String id) async {
    await _localDataSource.deletePlant(id);
    await _imageStore.deleteImages(id);
  }
}
