import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:water_it/core/database/app_database.dart';
import 'package:water_it/features/plants/data/datasources/care_task_local_data_source.dart';
import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';
import 'package:water_it/features/plants/data/models/care_task_model.dart';
import 'package:water_it/features/plants/data/models/plant_model.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late CareTaskLocalDataSource taskSource;
  late PlantLocalDataSource plantSource;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await AppDatabase.createSchema(db);
    taskSource = CareTaskLocalDataSourceImpl(db);
    plantSource = PlantLocalDataSourceImpl(db);
    await plantSource.upsertPlant(
      const PlantModel(id: 'plant-1', name: 'Monstera'),
    );
  });

  tearDown(() => db.close());

  test('round-trips every field of a task', () async {
    final task = CareTaskModel(
      id: 'task-1',
      plantId: 'plant-1',
      type: CareTaskType.fertilize,
      scheduleType: CareScheduleType.weekly,
      weekdays: const [1, 4],
      intervalDays: 0,
      preferredTime: DateTime(2026, 8, 4, 8, 30),
      notes: 'Half-strength in winter',
      active: false,
    );

    await taskSource.upsertTask(task);
    final loaded = (await taskSource.getTasksForPlant('plant-1')).single;

    expect(loaded.id, 'task-1');
    expect(loaded.type, CareTaskType.fertilize);
    expect(loaded.scheduleType, CareScheduleType.weekly);
    expect(loaded.weekdays, [1, 4]);
    expect(loaded.preferredTime, DateTime(2026, 8, 4, 8, 30));
    expect(loaded.notes, 'Half-strength in winter');
    expect(loaded.active, isFalse);
  });

  test('custom task keeps its label; interval schedule keeps its days',
      () async {
    await taskSource.upsertTask(
      const CareTaskModel(
        id: 'task-2',
        plantId: 'plant-1',
        type: CareTaskType.custom,
        customLabel: 'Rotate toward light',
        scheduleType: CareScheduleType.interval,
        intervalDays: 10,
      ),
    );

    final loaded = (await taskSource.getTasksForPlant('plant-1')).single;

    expect(loaded.type, CareTaskType.custom);
    expect(loaded.label, 'Rotate toward light');
    expect(loaded.scheduleType, CareScheduleType.interval);
    expect(loaded.intervalDays, 10);
  });

  test('deleteTask removes only that task', () async {
    await taskSource.upsertTask(
      const CareTaskModel(id: 'task-a', plantId: 'plant-1'),
    );
    await taskSource.upsertTask(
      const CareTaskModel(
        id: 'task-b',
        plantId: 'plant-1',
        type: CareTaskType.prune,
      ),
    );

    await taskSource.deleteTask('task-a');
    final remaining = await taskSource.getTasksForPlant('plant-1');

    expect(remaining.single.id, 'task-b');
  });

  test('getAllTasks returns tasks across every plant', () async {
    await plantSource.upsertPlant(
      const PlantModel(id: 'plant-2', name: 'Basil'),
    );
    await taskSource.upsertTask(
      const CareTaskModel(id: 'task-1', plantId: 'plant-1'),
    );
    await taskSource.upsertTask(
      const CareTaskModel(
        id: 'task-2',
        plantId: 'plant-2',
        type: CareTaskType.mist,
      ),
    );

    final all = await taskSource.getAllTasks();

    expect(all.map((t) => t.id).toSet(), {'task-1', 'task-2'});
  });

  test('water task saved via the task editor surfaces as a reminder',
      () async {
    await taskSource.upsertTask(
      const CareTaskModel(
        id: 'task-w',
        plantId: 'plant-1',
        type: CareTaskType.water,
        scheduleType: CareScheduleType.weekly,
        weekdays: [2, 5],
      ),
    );

    final plant = await plantSource.getPlant('plant-1');

    expect(plant!.reminders.single.id, 'task-w');
    expect(plant.reminders.single.weekdays, [2, 5]);
  });

  test('unknown type value falls back to custom instead of crashing',
      () async {
    await db.insert('care_tasks', {
      'id': 'task-x',
      'plant_id': 'plant-1',
      'type': 'sing_to_it',
      'schedule_type': 'weekly',
      'weekdays': '[1]',
      'interval_days': 0,
      'active': 1,
    });

    final loaded = (await taskSource.getTasksForPlant('plant-1')).single;

    expect(loaded.type, CareTaskType.custom);
  });
}
