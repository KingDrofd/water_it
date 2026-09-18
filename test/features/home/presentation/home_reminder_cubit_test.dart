import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_it/features/home/presentation/bloc/home_reminder_cubit.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/usecases/get_latest_water_events.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/domain/usecases/log_care_event.dart';

class MockGetPlants extends Mock implements GetPlants {}

class MockGetLatestWaterEvents extends Mock implements GetLatestWaterEvents {}

class MockLogCareEvent extends Mock implements LogCareEvent {}

void main() {
  late MockGetPlants getPlants;
  late MockGetLatestWaterEvents getLatestWaterEvents;
  late MockLogCareEvent logCareEvent;
  late HomeReminderCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      CareEvent(id: 'f', plantId: 'f', completedAt: DateTime(2026)),
    );
  });

  setUp(() {
    getPlants = MockGetPlants();
    getLatestWaterEvents = MockGetLatestWaterEvents();
    logCareEvent = MockLogCareEvent();
    cubit = HomeReminderCubit(getPlants, getLatestWaterEvents, logCareEvent);
  });

  tearDown(() => cubit.close());

  // A reminder due every day at midnight: its most recent due moment is
  // always today 00:00, so "overdue" only depends on the last event date.
  const dailyMidnightReminder = WateringReminder(
    id: 'rem-1',
    plantId: 'plant-1',
    frequencyDays: 7,
    weekdays: [1, 2, 3, 4, 5, 6, 7],
  );

  const plant = Plant(
    id: 'plant-1',
    name: 'Monstera',
    reminders: [dailyMidnightReminder],
  );

  test('flags reminder overdue when last event predates the latest due moment',
      () async {
    when(() => getPlants()).thenAnswer((_) async => [plant]);
    when(() => getLatestWaterEvents()).thenAnswer(
      (_) async =>
          {'plant-1': DateTime.now().subtract(const Duration(days: 8))},
    );

    await cubit.loadNextReminders();

    expect(cubit.state.status, HomeReminderStatus.loaded);
    expect(cubit.state.items.length, 1);
    expect(cubit.state.items.first.isOverdue, isTrue);
  });

  test('not overdue when a completion covers the latest due moment', () async {
    when(() => getPlants()).thenAnswer((_) async => [plant]);
    when(() => getLatestWaterEvents())
        .thenAnswer((_) async => {'plant-1': DateTime.now()});

    await cubit.loadNextReminders();

    expect(cubit.state.items.first.isOverdue, isFalse);
  });

  test('plant with no events at all is overdue', () async {
    when(() => getPlants()).thenAnswer((_) async => [plant]);
    when(() => getLatestWaterEvents()).thenAnswer((_) async => {});

    await cubit.loadNextReminders();

    expect(cubit.state.items.first.isOverdue, isTrue);
  });

  test('markDone logs a home-sourced water event and reloads', () async {
    when(() => getPlants()).thenAnswer((_) async => [plant]);
    when(() => getLatestWaterEvents())
        .thenAnswer((_) async => {'plant-1': DateTime.now()});
    when(() => logCareEvent(any())).thenAnswer((_) async {});

    await cubit.markDone('plant-1');

    final logged =
        verify(() => logCareEvent(captureAny())).captured.single as CareEvent;
    expect(logged.plantId, 'plant-1');
    expect(logged.type, CareEvent.waterType);
    expect(logged.source, CareEventSource.home);
    expect(cubit.state.status, HomeReminderStatus.loaded);
  });

  test('failure loading plants emits failure state', () async {
    when(() => getPlants()).thenThrow(Exception('db down'));

    await cubit.loadNextReminders();

    expect(cubit.state.status, HomeReminderStatus.failure);
  });
}
