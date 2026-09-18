import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/usecases/delete_care_task.dart';
import 'package:water_it/features/plants/domain/usecases/get_care_tasks.dart';
import 'package:water_it/features/plants/domain/usecases/save_care_task.dart';
import 'package:water_it/features/plants/presentation/bloc/care_task_cubit.dart';

class MockGetCareTasks extends Mock implements GetCareTasks {}

class MockSaveCareTask extends Mock implements SaveCareTask {}

class MockDeleteCareTask extends Mock implements DeleteCareTask {}

void main() {
  late MockGetCareTasks getCareTasks;
  late MockSaveCareTask saveCareTask;
  late MockDeleteCareTask deleteCareTask;
  late CareTaskCubit cubit;

  setUpAll(() {
    registerFallbackValue(const CareTask(id: 'f', plantId: 'f'));
  });

  setUp(() {
    getCareTasks = MockGetCareTasks();
    saveCareTask = MockSaveCareTask();
    deleteCareTask = MockDeleteCareTask();
    cubit = CareTaskCubit(getCareTasks, saveCareTask, deleteCareTask);
  });

  tearDown(() => cubit.close());

  const task = CareTask(
    id: 'task-1',
    plantId: 'plant-1',
    type: CareTaskType.mist,
    weekdays: [3],
  );

  test('load emits the plant tasks', () async {
    when(() => getCareTasks('plant-1')).thenAnswer((_) async => [task]);

    await cubit.load('plant-1');

    expect(cubit.state.status, CareTaskStatus.loaded);
    expect(cubit.state.tasks, [task]);
  });

  test('load failure emits failure state', () async {
    when(() => getCareTasks('plant-1')).thenThrow(Exception('boom'));

    await cubit.load('plant-1');

    expect(cubit.state.status, CareTaskStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('save persists the task and reloads', () async {
    when(() => saveCareTask(any())).thenAnswer((_) async {});
    when(() => getCareTasks('plant-1')).thenAnswer((_) async => [task]);

    await cubit.save(task);

    verify(() => saveCareTask(task)).called(1);
    expect(cubit.state.status, CareTaskStatus.loaded);
    expect(cubit.state.tasks, [task]);
  });

  test('save failure keeps the error without reloading', () async {
    when(() => saveCareTask(any())).thenThrow(Exception('disk full'));

    await cubit.save(task);

    verifyNever(() => getCareTasks(any()));
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('delete removes the task and reloads', () async {
    when(() => deleteCareTask('task-1')).thenAnswer((_) async {});
    when(() => getCareTasks('plant-1')).thenAnswer((_) async => []);

    await cubit.delete(task);

    verify(() => deleteCareTask('task-1')).called(1);
    expect(cubit.state.tasks, isEmpty);
  });
}
