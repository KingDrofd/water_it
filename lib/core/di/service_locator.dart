import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:water_it/core/database/app_database.dart';
import 'package:water_it/features/backup/data/backup_service.dart';
import 'package:water_it/features/plants/data/datasources/care_event_local_data_source.dart';
import 'package:water_it/features/plants/data/datasources/care_task_local_data_source.dart';
import 'package:water_it/features/plants/data/datasources/plant_image_store.dart';
import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';
import 'package:water_it/features/plants/data/datasources/room_local_data_source.dart';
import 'package:water_it/features/plants/data/repositories/care_log_repository_impl.dart';
import 'package:water_it/features/plants/data/repositories/care_task_repository_impl.dart';
import 'package:water_it/features/plants/data/repositories/plants_repository_impl.dart';
import 'package:water_it/features/plants/data/repositories/room_repository_impl.dart';
import 'package:water_it/features/plants/domain/repositories/care_log_repository.dart';
import 'package:water_it/features/plants/domain/repositories/care_task_repository.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';
import 'package:water_it/features/plants/domain/repositories/room_repository.dart';
import 'package:water_it/features/plants/domain/usecases/delete_care_task.dart';
import 'package:water_it/features/plants/domain/usecases/delete_plant.dart';
import 'package:water_it/features/plants/domain/usecases/delete_room.dart';
import 'package:water_it/features/plants/domain/usecases/get_care_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_all_care_tasks.dart';
import 'package:water_it/features/plants/domain/usecases/get_care_tasks.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_care_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/domain/usecases/get_rooms.dart';
import 'package:water_it/features/plants/domain/services/reminder_scheduler.dart';
import 'package:water_it/features/plants/domain/usecases/log_care_event.dart';
import 'package:water_it/features/plants/domain/usecases/save_care_task.dart';
import 'package:water_it/features/plants/domain/usecases/save_room.dart';
import 'package:water_it/features/plants/domain/usecases/upsert_plant.dart';
import 'package:water_it/features/plants/presentation/bloc/care_task_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/room_cubit.dart';
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

  getIt.registerSingletonAsync<PlantImageStore>(() async {
    final docs = await getApplicationDocumentsDirectory();
    return PlantImageStoreImpl(Directory(p.join(docs.path, 'plant_images')));
  });

  getIt.registerSingletonWithDependencies<PlantsRepository>(
    () => PlantsRepositoryImpl(
      getIt<PlantLocalDataSource>(),
      getIt<PlantImageStore>(),
    ),
    dependsOn: [PlantLocalDataSource, PlantImageStore],
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

  getIt.registerSingletonWithDependencies<CareEventLocalDataSource>(
    () => CareEventLocalDataSourceImpl(getIt<Database>()),
    dependsOn: [Database],
  );
  getIt.registerSingletonWithDependencies<CareLogRepository>(
    () => CareLogRepositoryImpl(getIt<CareEventLocalDataSource>()),
    dependsOn: [CareEventLocalDataSource],
  );
  getIt.registerSingletonWithDependencies<LogCareEvent>(
    () => LogCareEvent(getIt<CareLogRepository>()),
    dependsOn: [CareLogRepository],
  );
  getIt.registerSingletonWithDependencies<GetCareEvents>(
    () => GetCareEvents(getIt<CareLogRepository>()),
    dependsOn: [CareLogRepository],
  );

  getIt.registerSingletonWithDependencies<CareTaskLocalDataSource>(
    () => CareTaskLocalDataSourceImpl(getIt<Database>()),
    dependsOn: [Database],
  );
  getIt.registerSingletonWithDependencies<CareTaskRepository>(
    () => CareTaskRepositoryImpl(getIt<CareTaskLocalDataSource>()),
    dependsOn: [CareTaskLocalDataSource],
  );
  getIt.registerSingletonWithDependencies<GetCareTasks>(
    () => GetCareTasks(getIt<CareTaskRepository>()),
    dependsOn: [CareTaskRepository],
  );
  getIt.registerSingletonWithDependencies<GetAllCareTasks>(
    () => GetAllCareTasks(getIt<CareTaskRepository>()),
    dependsOn: [CareTaskRepository],
  );
  getIt.registerSingletonWithDependencies<GetLatestCareEvents>(
    () => GetLatestCareEvents(getIt<CareLogRepository>()),
    dependsOn: [CareLogRepository],
  );
  getIt.registerSingletonWithDependencies<SaveCareTask>(
    () => SaveCareTask(getIt<CareTaskRepository>()),
    dependsOn: [CareTaskRepository],
  );
  getIt.registerSingletonWithDependencies<DeleteCareTask>(
    () => DeleteCareTask(getIt<CareTaskRepository>()),
    dependsOn: [CareTaskRepository],
  );
  getIt.registerFactory<CareTaskCubit>(
    () => CareTaskCubit(
      getIt<GetCareTasks>(),
      getIt<SaveCareTask>(),
      getIt<DeleteCareTask>(),
    ),
  );

  getIt.registerSingletonWithDependencies<RoomLocalDataSource>(
    () => RoomLocalDataSourceImpl(getIt<Database>()),
    dependsOn: [Database],
  );
  getIt.registerSingletonWithDependencies<RoomRepository>(
    () => RoomRepositoryImpl(getIt<RoomLocalDataSource>()),
    dependsOn: [RoomLocalDataSource],
  );
  getIt.registerSingletonWithDependencies<GetRooms>(
    () => GetRooms(getIt<RoomRepository>()),
    dependsOn: [RoomRepository],
  );
  getIt.registerSingletonWithDependencies<SaveRoom>(
    () => SaveRoom(getIt<RoomRepository>()),
    dependsOn: [RoomRepository],
  );
  getIt.registerSingletonWithDependencies<DeleteRoom>(
    () => DeleteRoom(getIt<RoomRepository>()),
    dependsOn: [RoomRepository],
  );
  getIt.registerFactory<RoomCubit>(
    () => RoomCubit(
      getIt<GetRooms>(),
      getIt<SaveRoom>(),
      getIt<DeleteRoom>(),
    ),
  );

  getIt.registerSingletonWithDependencies<BackupService>(
    () => BackupService(getIt<Database>(), getIt<PlantImageStore>()),
    dependsOn: [Database, PlantImageStore],
  );

  getIt.registerSingletonAsync<NotificationService>(() async {
    final service = NotificationService(FlutterLocalNotificationsPlugin());
    await service.initialize();
    return service;
  });

  getIt.registerSingletonWithDependencies<ReminderScheduler>(
    () => ReminderScheduler(
      getIt<GetPlants>(),
      getIt<CareTaskRepository>(),
      getIt<CareLogRepository>(),
      getIt<NotificationService>(),
    ),
    dependsOn: [
      GetPlants,
      CareTaskRepository,
      CareLogRepository,
      NotificationService,
    ],
  );

  getIt.registerSingletonWithDependencies<PlantListCubit>(
    () => PlantListCubit(
      getIt<GetPlants>(),
      getIt<DeletePlant>(),
      getIt<GetAllCareTasks>(),
      getIt<GetLatestCareEvents>(),
      getIt<ReminderScheduler>(),
    ),
    dependsOn: [
      GetPlants,
      DeletePlant,
      GetAllCareTasks,
      GetLatestCareEvents,
      ReminderScheduler,
    ],
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
    () => HomeReminderCubit(
      getIt<GetPlants>(),
      getIt<GetAllCareTasks>(),
      getIt<GetLatestCareEvents>(),
      getIt<GetRooms>(),
      getIt<LogCareEvent>(),
    ),
  );

  await getIt.allReady();
}
