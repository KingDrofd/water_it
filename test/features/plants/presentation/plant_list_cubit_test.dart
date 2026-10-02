import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/services/care_task_schedule.dart';
import 'package:water_it/features/plants/domain/services/reminder_scheduler.dart';
import 'package:water_it/features/plants/domain/usecases/delete_plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_all_care_tasks.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_care_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';

class MockGetPlants extends Mock implements GetPlants {}

class MockDeletePlant extends Mock implements DeletePlant {}

class MockGetAllCareTasks extends Mock implements GetAllCareTasks {}

class MockGetLatestCareEvents extends Mock implements GetLatestCareEvents {}

class MockReminderScheduler extends Mock implements ReminderScheduler {}

void main() {
  // Monday 2026-09-21, 09:41.
  final now = DateTime(2026, 9, 21, 9, 41);
  final longAgo = DateTime(2026, 8, 1);

  late MockGetPlants getPlants;
  late MockGetAllCareTasks getAllCareTasks;
  late MockGetLatestCareEvents getLatestCareEvents;
  late MockReminderScheduler reminderScheduler;
  late PlantListCubit cubit;

  setUp(() {
    getPlants = MockGetPlants();
    getAllCareTasks = MockGetAllCareTasks();
    getLatestCareEvents = MockGetLatestCareEvents();
    reminderScheduler = MockReminderScheduler();
    when(() => reminderScheduler.rescheduleAll()).thenAnswer((_) async {});
    when(() => getLatestCareEvents()).thenAnswer((_) async => {});
    cubit = PlantListCubit(
      getPlants,
      MockDeletePlant(),
      getAllCareTasks,
      getLatestCareEvents,
      reminderScheduler,
      clock: () => now,
    );
  });

  tearDown(() => cubit.close());

  const plants = [
    Plant(id: 'ficus', name: 'Ficus'),
    Plant(id: 'cactus', name: 'Cactus'),
  ];

  test('picks each plant\'s most urgent task across types', () async {
    when(() => getPlants()).thenAnswer((_) async => plants);
    // Last Thursday's mist was done, so only the water is outstanding.
    when(() => getLatestCareEvents()).thenAnswer(
      (_) async => {
        'ficus': {'mist': DateTime(2026, 9, 17)},
      },
    );
    when(() => getAllCareTasks()).thenAnswer(
      (_) async => [
        // Upcoming mist on Thursday...
        CareTask(
          id: 'mist',
          plantId: 'ficus',
          type: CareTaskType.mist,
          weekdays: const [4],
          createdAt: longAgo,
        ),
        // ...but water missed yesterday wins.
        CareTask(
          id: 'water',
          plantId: 'ficus',
          weekdays: const [7],
          createdAt: longAgo,
        ),
      ],
    );

    await cubit.loadPlants();

    final next = cubit.state.nextTasks['ficus']!;
    expect(next.task.id, 'water');
    expect(next.state, TaskDueState.overdue);
    expect(cubit.state.overduePlantIds, {'ficus'});
    expect(cubit.state.nextTasks.containsKey('cactus'), isFalse);
  });

  test('among upcoming tasks, the soonest wins', () async {
    when(() => getPlants()).thenAnswer((_) async => plants);
    when(() => getAllCareTasks()).thenAnswer(
      (_) async => [
        CareTask(
          id: 'fri',
          plantId: 'cactus',
          weekdays: const [5],
          createdAt: DateTime(2026, 9, 21),
        ),
        CareTask(
          id: 'wed',
          plantId: 'cactus',
          type: CareTaskType.prune,
          weekdays: const [3],
          createdAt: DateTime(2026, 9, 21),
        ),
      ],
    );

    await cubit.loadPlants();

    expect(cubit.state.nextTasks['cactus']!.task.id, 'wed');
    expect(cubit.state.overduePlantIds, isEmpty);
  });

  test('loadPlants failure emits failure state', () async {
    when(() => getPlants()).thenThrow(Exception('db down'));

    await cubit.loadPlants();

    expect(cubit.state.status, PlantListStatus.failure);
  });

  test('notification scheduling failure does not break the load', () async {
    when(() => getPlants()).thenAnswer((_) async => plants);
    when(() => getAllCareTasks()).thenAnswer((_) async => []);
    when(() => reminderScheduler.rescheduleAll())
        .thenThrow(Exception('no alarm permission'));

    await cubit.loadPlants();

    expect(cubit.state.status, PlantListStatus.loaded);
  });
}
