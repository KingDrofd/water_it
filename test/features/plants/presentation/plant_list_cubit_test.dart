import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/services/reminder_scheduler.dart';
import 'package:water_it/features/plants/domain/usecases/delete_plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_water_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';

class MockGetPlants extends Mock implements GetPlants {}

class MockDeletePlant extends Mock implements DeletePlant {}

class MockGetLatestWaterEvents extends Mock implements GetLatestWaterEvents {}

class MockReminderScheduler extends Mock implements ReminderScheduler {}

void main() {
  late MockGetPlants getPlants;
  late MockDeletePlant deletePlant;
  late MockGetLatestWaterEvents getLatestWaterEvents;
  late MockReminderScheduler reminderScheduler;
  late PlantListCubit cubit;

  setUpAll(() {
    registerFallbackValue(<Plant>[]);
  });

  setUp(() {
    getPlants = MockGetPlants();
    deletePlant = MockDeletePlant();
    getLatestWaterEvents = MockGetLatestWaterEvents();
    reminderScheduler = MockReminderScheduler();
    when(() => reminderScheduler.rescheduleAll()).thenAnswer((_) async {});
    cubit = PlantListCubit(
      getPlants,
      deletePlant,
      getLatestWaterEvents,
      reminderScheduler,
    );
  });

  tearDown(() => cubit.close());

  // Due every day, so the plant is overdue unless watered since today's
  // due moment.
  const dailyReminder = WateringReminder(
    id: 'rem-1',
    plantId: 'plant-1',
    frequencyDays: 7,
    weekdays: [1, 2, 3, 4, 5, 6, 7],
  );

  const overduePlant = Plant(
    id: 'plant-1',
    name: 'Monstera',
    reminders: [dailyReminder],
  );

  const noReminderPlant = Plant(id: 'plant-2', name: 'Cactus');

  test('loadPlants flags plants with uncovered due moments as overdue',
      () async {
    when(() => getPlants())
        .thenAnswer((_) async => [overduePlant, noReminderPlant]);
    when(() => getLatestWaterEvents()).thenAnswer((_) async => {});

    await cubit.loadPlants();

    expect(cubit.state.status, PlantListStatus.loaded);
    expect(cubit.state.overduePlantIds, {'plant-1'});
  });

  test('loadPlants clears overdue when a recent watering covers the due moment',
      () async {
    when(() => getPlants()).thenAnswer((_) async => [overduePlant]);
    when(() => getLatestWaterEvents())
        .thenAnswer((_) async => {'plant-1': DateTime.now()});

    await cubit.loadPlants();

    expect(cubit.state.overduePlantIds, isEmpty);
  });

  test('loadPlants failure emits failure state', () async {
    when(() => getPlants()).thenThrow(Exception('db down'));

    await cubit.loadPlants();

    expect(cubit.state.status, PlantListStatus.failure);
  });

  test('notification scheduling failure does not break the load', () async {
    when(() => getPlants()).thenAnswer((_) async => [overduePlant]);
    when(() => getLatestWaterEvents()).thenAnswer((_) async => {});
    when(() => reminderScheduler.rescheduleAll())
        .thenThrow(Exception('no alarm permission'));

    await cubit.loadPlants();

    expect(cubit.state.status, PlantListStatus.loaded);
  });
}
