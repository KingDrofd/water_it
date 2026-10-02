import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/usecases/get_care_events.dart';
import 'package:water_it/features/plants/domain/usecases/log_care_event.dart';
import 'package:water_it/features/plants/presentation/bloc/care_log_cubit.dart';

class MockGetCareEvents extends Mock implements GetCareEvents {}

class MockLogCareEvent extends Mock implements LogCareEvent {}

void main() {
  late MockGetCareEvents getCareEvents;
  late MockLogCareEvent logCareEvent;
  late CareLogCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      CareEvent(id: 'f', plantId: 'f', completedAt: DateTime(2026)),
    );
  });

  setUp(() {
    getCareEvents = MockGetCareEvents();
    logCareEvent = MockLogCareEvent();
    cubit = CareLogCubit(getCareEvents, logCareEvent);
  });

  tearDown(() => cubit.close());

  final event = CareEvent(
    id: 'e1',
    plantId: 'plant-1',
    completedAt: DateTime(2026, 7, 22, 9),
  );

  test('load emits events for the plant', () async {
    when(() => getCareEvents('plant-1')).thenAnswer((_) async => [event]);

    await cubit.load('plant-1');

    expect(cubit.state.status, CareLogStatus.loaded);
    expect(cubit.state.events, [event]);
  });

  test('load failure emits failure with message', () async {
    when(() => getCareEvents('plant-1')).thenThrow(Exception('boom'));

    await cubit.load('plant-1');

    expect(cubit.state.status, CareLogStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  const fertilize = CareTask(
    id: 'task-f',
    plantId: 'plant-1',
    type: CareTaskType.fertilize,
  );

  test('markDone logs a detail-sourced event of the task type', () async {
    when(() => logCareEvent(any())).thenAnswer((_) async {});
    when(() => getCareEvents('plant-1')).thenAnswer((_) async => [event]);

    await cubit.markDone(fertilize);

    final logged =
        verify(() => logCareEvent(captureAny())).captured.single as CareEvent;
    expect(logged.plantId, 'plant-1');
    expect(logged.taskId, 'task-f');
    expect(logged.type, 'fertilize');
    expect(logged.source, CareEventSource.detail);
    expect(cubit.state.status, CareLogStatus.loaded);
    expect(cubit.state.isLogging, isFalse);
    expect(cubit.state.events, [event]);
  });

  test('markDone failure clears logging flag and keeps message', () async {
    when(() => logCareEvent(any())).thenThrow(Exception('disk full'));

    await cubit.markDone(fertilize);

    expect(cubit.state.isLogging, isFalse);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('latestByType keeps the newest completion of each type', () {
    final state = CareLogState(
      events: [
        CareEvent(id: 'a', plantId: 'p', completedAt: DateTime(2026, 9, 1)),
        CareEvent(id: 'b', plantId: 'p', completedAt: DateTime(2026, 9, 9)),
        CareEvent(
          id: 'c',
          plantId: 'p',
          type: 'mist',
          completedAt: DateTime(2026, 9, 5),
        ),
      ],
    );

    expect(state.latestByType, {
      'water': DateTime(2026, 9, 9),
      'mist': DateTime(2026, 9, 5),
    });
  });
}
