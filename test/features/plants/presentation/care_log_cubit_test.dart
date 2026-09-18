import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
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

  test('markWatered logs a detail-sourced event and refreshes', () async {
    when(() => logCareEvent(any())).thenAnswer((_) async {});
    when(() => getCareEvents('plant-1')).thenAnswer((_) async => [event]);

    await cubit.markWatered('plant-1');

    final logged =
        verify(() => logCareEvent(captureAny())).captured.single as CareEvent;
    expect(logged.plantId, 'plant-1');
    expect(logged.source, CareEventSource.detail);
    expect(cubit.state.status, CareLogStatus.loaded);
    expect(cubit.state.isLogging, isFalse);
    expect(cubit.state.events, [event]);
  });

  test('markWatered failure clears logging flag and keeps message', () async {
    when(() => logCareEvent(any())).thenThrow(Exception('disk full'));

    await cubit.markWatered('plant-1');

    expect(cubit.state.isLogging, isFalse);
    expect(cubit.state.errorMessage, isNotNull);
  });
}
