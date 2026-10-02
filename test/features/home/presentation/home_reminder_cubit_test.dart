import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_it/features/home/presentation/bloc/home_reminder_cubit.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/usecases/get_all_care_tasks.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_care_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/domain/usecases/get_rooms.dart';
import 'package:water_it/features/plants/domain/usecases/log_care_event.dart';

class MockGetPlants extends Mock implements GetPlants {}

class MockGetAllCareTasks extends Mock implements GetAllCareTasks {}

class MockGetLatestCareEvents extends Mock implements GetLatestCareEvents {}

class MockGetRooms extends Mock implements GetRooms {}

class MockLogCareEvent extends Mock implements LogCareEvent {}

void main() {
  // Monday 2026-09-21, 09:41.
  final now = DateTime(2026, 9, 21, 9, 41);
  final longAgo = DateTime(2026, 8, 1);

  late MockGetPlants getPlants;
  late MockGetAllCareTasks getAllCareTasks;
  late MockGetLatestCareEvents getLatestCareEvents;
  late MockGetRooms getRooms;
  late MockLogCareEvent logCareEvent;
  late HomeReminderCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      CareEvent(id: 'f', plantId: 'f', completedAt: DateTime(2026)),
    );
  });

  const plants = [
    Plant(id: 'monstera', name: 'Monstera', roomId: 'living'),
    Plant(id: 'basil', name: 'Basil'),
    Plant(id: 'ficus', name: 'Ficus'),
  ];

  setUp(() {
    getPlants = MockGetPlants();
    getAllCareTasks = MockGetAllCareTasks();
    getLatestCareEvents = MockGetLatestCareEvents();
    getRooms = MockGetRooms();
    logCareEvent = MockLogCareEvent();
    when(() => getPlants()).thenAnswer((_) async => plants);
    when(() => getRooms()).thenAnswer(
      (_) async => const [Room(id: 'living', name: 'Living room')],
    );
    cubit = HomeReminderCubit(
      getPlants,
      getAllCareTasks,
      getLatestCareEvents,
      getRooms,
      logCareEvent,
      clock: () => now,
    );
  });

  tearDown(() => cubit.close());

  test('lists every task type due today, overdue first, with room names',
      () async {
    when(() => getAllCareTasks()).thenAnswer(
      (_) async => [
        // Due today (last Monday done).
        CareTask(
          id: 'w',
          plantId: 'monstera',
          weekdays: const [1],
          preferredTime: DateTime(2026, 1, 1, 8),
          createdAt: longAgo,
        ),
        // Fertilize every 7 days, last done a week ago: due today.
        CareTask(
          id: 'f',
          plantId: 'basil',
          type: CareTaskType.fertilize,
          scheduleType: CareScheduleType.interval,
          intervalDays: 7,
          createdAt: longAgo,
        ),
        // Sunday water, never done: overdue.
        CareTask(
          id: 'o',
          plantId: 'ficus',
          weekdays: const [7],
          createdAt: longAgo,
        ),
        // Thursday only: not due, must not appear.
        CareTask(
          id: 'later',
          plantId: 'basil',
          type: CareTaskType.mist,
          weekdays: const [4],
          createdAt: longAgo,
        ),
      ],
    );
    when(() => getLatestCareEvents()).thenAnswer(
      (_) async => {
        'monstera': {'water': DateTime(2026, 9, 14, 8)},
        'basil': {
          'fertilize': DateTime(2026, 9, 14, 12),
          'mist': DateTime(2026, 9, 17),
        },
      },
    );

    await cubit.loadNextReminders();

    final items = cubit.state.items;
    expect(items.map((i) => i.taskId).toList(), ['o', 'w', 'f']);
    expect(items.first.isOverdue, isTrue);
    expect(items[1].roomName, 'Living room');
    expect(items[2].type, CareTaskType.fertilize);
    expect(items[2].label, 'Fertilize');
  });

  test('nothing due gives an empty list', () async {
    when(() => getAllCareTasks()).thenAnswer(
      (_) async => [
        CareTask(
          id: 'later',
          plantId: 'basil',
          weekdays: const [4],
          createdAt: DateTime(2026, 9, 21),
        ),
      ],
    );
    when(() => getLatestCareEvents()).thenAnswer((_) async => {});

    await cubit.loadNextReminders();

    expect(cubit.state.status, HomeReminderStatus.loaded);
    expect(cubit.state.items, isEmpty);
  });

  test('markDone logs a home-sourced event of the task type', () async {
    final task = CareTask(
      id: 'f',
      plantId: 'basil',
      type: CareTaskType.fertilize,
      scheduleType: CareScheduleType.interval,
      intervalDays: 7,
      createdAt: longAgo,
    );
    when(() => getAllCareTasks()).thenAnswer((_) async => [task]);
    when(() => getLatestCareEvents()).thenAnswer((_) async => {});
    when(() => logCareEvent(any())).thenAnswer((_) async {});

    await cubit.loadNextReminders();
    await cubit.markDone(cubit.state.items.single);

    final logged =
        verify(() => logCareEvent(captureAny())).captured.single as CareEvent;
    expect(logged.plantId, 'basil');
    expect(logged.taskId, 'f');
    expect(logged.type, 'fertilize');
    expect(logged.source, CareEventSource.home);
    expect(logged.completedAt, now);
  });

  test('failure loading emits failure state', () async {
    when(() => getAllCareTasks()).thenThrow(Exception('db down'));

    await cubit.loadNextReminders();

    expect(cubit.state.status, HomeReminderStatus.failure);
  });
}
