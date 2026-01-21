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
import 'package:water_it/features/home/data/datasources/open_weather_data_source.dart';
import 'package:water_it/features/home/data/repositories/weather_repository_impl.dart';
import 'package:water_it/features/home/domain/repositories/weather_repository.dart';
import 'package:water_it/features/home/domain/usecases/get_weather_slots.dart';
import 'package:water_it/features/home/presentation/bloc/home_weather_cubit.dart';
import 'package:water_it/features/home/presentation/bloc/home_reminder_cubit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:water_it/core/notifications/notification_service.dart';

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

  getIt.registerSingletonAsync<NotificationService>(() async {
    final service = NotificationService(FlutterLocalNotificationsPlugin());
    await service.initialize();
    return service;
  });

  getIt.registerSingletonWithDependencies<PlantListCubit>(
    () => PlantListCubit(
      getIt<GetPlants>(),
      getIt<DeletePlant>(),
      getIt<NotificationService>(),
    ),
    dependsOn: [GetPlants, DeletePlant, NotificationService],
  );

  getIt.registerLazySingleton<OpenWeatherDataSource>(
    () => OpenWeatherDataSource(),
  );
  getIt.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(getIt<OpenWeatherDataSource>()),
  );
  getIt.registerFactory<GetWeatherSlots>(
    () => GetWeatherSlots(getIt<WeatherRepository>()),
  );
  getIt.registerFactory<HomeWeatherCubit>(
    () => HomeWeatherCubit(getIt<GetWeatherSlots>()),
  );
  getIt.registerFactory<HomeReminderCubit>(
    () => HomeReminderCubit(getIt<GetPlants>()),
  );

  await getIt.allReady();
}
