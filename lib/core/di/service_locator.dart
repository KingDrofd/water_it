import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:water_it/core/database/app_database.dart';
import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';
import 'package:water_it/features/plants/data/repositories/plants_repository_impl.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';
import 'package:water_it/features/plants/domain/usecases/delete_plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/domain/usecases/upsert_plant.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerSingletonAsync<Database>(() => AppDatabase.open());

  getIt.registerSingletonWithDependencies<PlantLocalDataSource>(
    () => PlantLocalDataSourceImpl(getIt<Database>()),
    dependsOn: [Database],
  );

  getIt.registerSingletonWithDependencies<PlantsRepository>(
    () => PlantsRepositoryImpl(getIt<PlantLocalDataSource>()),
    dependsOn: [PlantLocalDataSource],
  );

  getIt.registerSingletonWithDependencies<GetPlants>(
    () => GetPlants(getIt<PlantsRepository>()),
    dependsOn: [PlantsRepository],
  );
  getIt.registerSingletonWithDependencies<GetPlant>(
    () => GetPlant(getIt<PlantsRepository>()),
    dependsOn: [PlantsRepository],
  );
  getIt.registerSingletonWithDependencies<UpsertPlant>(
    () => UpsertPlant(getIt<PlantsRepository>()),
    dependsOn: [PlantsRepository],
  );
  getIt.registerSingletonWithDependencies<DeletePlant>(
    () => DeletePlant(getIt<PlantsRepository>()),
    dependsOn: [PlantsRepository],
  );

  getIt.registerSingletonWithDependencies<PlantListCubit>(
    () => PlantListCubit(getIt<GetPlants>(), getIt<DeletePlant>()),
    dependsOn: [GetPlants, DeletePlant],
  );

  await getIt.allReady();
}
