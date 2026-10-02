import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:water_it/core/database/app_database.dart';
import 'package:water_it/features/plants/data/datasources/care_event_local_data_source.dart';
import 'package:water_it/features/plants/data/datasources/plant_image_store.dart';
import 'package:water_it/features/plants/data/models/care_event_model.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';
import 'package:water_it/features/plants/data/models/plant_model.dart';
import 'package:water_it/features/plants/data/repositories/plants_repository_impl.dart';
import 'package:water_it/features/plants/domain/entities/care_profile.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late PlantLocalDataSource dataSource;
  late Directory imageBaseDir;
  late Directory sourceDir;
  late PlantImageStore imageStore;
  late PlantsRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await AppDatabase.createSchema(db);
    dataSource = PlantLocalDataSourceImpl(db);
    imageBaseDir = await Directory.systemTemp.createTemp('plant_images_test');
    sourceDir = await Directory.systemTemp.createTemp('plant_sources_test');
    imageStore = PlantImageStoreImpl(imageBaseDir);
    repository = PlantsRepositoryImpl(dataSource, imageStore);
  });

  tearDown(() async {
    await db.close();
    for (final dir in [imageBaseDir, sourceDir]) {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  });

  PlantModel buildModel({String id = 'plant-1'}) {
    return PlantModel(
      id: id,
      name: 'Fiddle Leaf Fig',
      ageMonths: 12,
      description: 'Loves bright, indirect light.',
      origin: 'West Africa',
      soilType: SoilKind.wellDraining,
      preferredLighting: LightingLevel.brightIndirect,
      wateringLevel: WateringLevel.moderate,
      careNotes: 'Wipe leaves monthly',
      scientificName: 'Ficus lyrata',
      imagePaths: const ['path/a.jpg', 'path/b.jpg'],
      reminders: const [
        WateringReminderModel(
          id: 'rem-1',
          plantId: 'plant-1',
          frequencyDays: 7,
          notes: 'Check soil moisture first',
        ),
        WateringReminderModel(
          id: 'rem-2',
          plantId: 'plant-1',
          frequencyDays: 14,
        ),
      ],
    );
  }

  test('upsert and get plant roundtrip via data source', () async {
    final model = buildModel();

    await dataSource.upsertPlant(model);
    final loaded = await dataSource.getPlant(model.id);

    expect(loaded, isNotNull);
    expect(loaded!.name, model.name);
    expect(loaded.imagePaths, model.imagePaths);
    expect(loaded.reminders.length, model.reminders.length);
    expect(
      loaded.reminders.map((r) => r.frequencyDays),
      containsAll([7, 14]),
    );
  });

  test('delete plant cascades reminders', () async {
    final model = buildModel();

    await dataSource.upsertPlant(model);
    await dataSource.deletePlant(model.id);

    final plants = await dataSource.getPlants();
    expect(plants, isEmpty);
  });

  test('repository maps domain Plant into storage and back', () async {
    const domainPlant = Plant(
      id: 'plant-2',
      name: 'Snake Plant',
      description: 'Low-maintenance',
      origin: 'West Africa',
      soilType: SoilKind.wellDraining,
      preferredLighting: LightingLevel.lowLight,
      wateringLevel: WateringLevel.low,
      scientificName: 'Dracaena trifasciata',
      reminders: [
        WateringReminder(
          id: 'rem-3',
          plantId: 'plant-2',
          frequencyDays: 21,
          notes: 'Water sparingly',
        ),
      ],
    );

    await repository.upsertPlant(domainPlant);
    final loaded = await repository.getPlant(domainPlant.id);

    expect(loaded, isNotNull);
    expect(loaded!.name, domainPlant.name);
    expect(loaded.reminders.first.frequencyDays, 21);
    expect(loaded.soilType, SoilKind.wellDraining);
  });

  test('reminder created_at survives the care_tasks round-trip', () async {
    final created = DateTime(2026, 9, 17, 12, 30);
    await dataSource.upsertPlant(
      PlantModel(
        id: 'plant-created',
        name: 'Fern',
        reminders: [
          WateringReminderModel(
            id: 'rem-created',
            plantId: 'plant-created',
            frequencyDays: 7,
            weekdays: const [1],
            createdAt: created,
          ),
        ],
      ),
    );

    final loaded = await dataSource.getPlant('plant-created');

    expect(loaded!.reminders.single.createdAt, created);
  });

  test('rejects plant with empty id or name', () async {
    final invalid = buildModel(id: '');

    expect(() => dataSource.upsertPlant(invalid), throwsArgumentError);
  });

  test('rejects reminders with empty id or non-positive frequency', () async {
    final invalid = PlantModel(
      id: 'plant-3',
      name: 'Monstera',
      reminders: const [
        WateringReminderModel(
          id: '',
          plantId: 'plant-3',
          frequencyDays: 0,
        ),
      ],
    );

    expect(() => dataSource.upsertPlant(invalid), throwsArgumentError);
  });

  test('persists and restores optional/null fields and multiple reminders', () async {
    const plantId = 'plant-optional';
    final model = PlantModel(
      id: plantId,
      name: 'Pothos',
      description: null,
      origin: null,
      soilType: null,
      preferredLighting: null,
      wateringLevel: null,
      scientificName: null,
      imagePaths: const [],
      reminders: const [
        WateringReminderModel(
          id: 'rem-a',
          plantId: plantId,
          frequencyDays: 5,
        ),
        WateringReminderModel(
          id: 'rem-b',
          plantId: plantId,
          frequencyDays: 10,
          notes: 'Skip if soil damp',
        ),
      ],
    );

    await dataSource.upsertPlant(model);
    final loaded = await dataSource.getPlant(plantId);

    expect(loaded, isNotNull);
    expect(loaded!.description, isNull);
    expect(loaded.reminders.length, 2);
    expect(
      loaded.reminders.map((r) => r.frequencyDays),
      containsAll([5, 10]),
    );
  });

  test('upsert replaces existing plant and reminders', () async {
    final original = buildModel(id: 'plant-replace');
    final updated = original.copyWith(
      name: 'Updated Name',
      imagePaths: ['new/image.jpg'],
      reminders: const [
        WateringReminderModel(
          id: 'rem-new',
          plantId: 'plant-replace',
          frequencyDays: 3,
        ),
      ],
    );

    await dataSource.upsertPlant(original);
    await dataSource.upsertPlant(updated);

    final loaded = await dataSource.getPlant(updated.id);
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Updated Name');
    expect(loaded.imagePaths, ['new/image.jpg']);
    expect(loaded.reminders.length, 1);
    expect(loaded.reminders.first.frequencyDays, 3);
  });

  test('getPlants returns rows; caller can order externally as needed', () async {
    await dataSource.upsertPlant(buildModel(id: 'b'));
    await dataSource.upsertPlant(buildModel(id: 'a'));

    final plants = await dataSource.getPlants();

    expect(plants.length, 2);
    final sortedNames = plants.map((p) => p.name).toList()..sort();
    expect(sortedNames, isNotEmpty);
  });

  test('water reminders are stored as care_tasks rows with schedule_type',
      () async {
    const plantId = 'plant-schedule';
    final model = PlantModel(
      id: plantId,
      name: 'Monstera',
      reminders: const [
        WateringReminderModel(
          id: 'rem-weekly',
          plantId: plantId,
          frequencyDays: 7,
          weekdays: [1, 4],
        ),
        WateringReminderModel(
          id: 'rem-interval',
          plantId: plantId,
          frequencyDays: 10,
        ),
      ],
    );

    await dataSource.upsertPlant(model);
    final rows = await db.query('care_tasks', orderBy: 'id');

    expect(rows.length, 2);
    final byId = {for (final r in rows) r['id']: r};
    expect(byId['rem-weekly']!['type'], 'water');
    expect(byId['rem-weekly']!['schedule_type'], 'weekly');
    expect(byId['rem-interval']!['schedule_type'], 'interval');
    expect(byId['rem-interval']!['interval_days'], 10);
  });

  test('upsert leaves non-water care tasks untouched', () async {
    const model = PlantModel(
      id: 'plant-mixed',
      name: 'Mixed Care',
      reminders: [
        WateringReminderModel(
          id: 'rem-water',
          plantId: 'plant-mixed',
          frequencyDays: 7,
          weekdays: [2],
        ),
      ],
    );
    await dataSource.upsertPlant(model);
    await db.insert('care_tasks', {
      'id': 'task-fertilize',
      'plant_id': 'plant-mixed',
      'type': 'fertilize',
      'schedule_type': 'interval',
      'interval_days': 30,
      'active': 1,
    });

    await dataSource.upsertPlant(model.copyWith(name: 'Renamed'));

    final rows = await db.query(
      'care_tasks',
      where: 'plant_id = ?',
      whereArgs: ['plant-mixed'],
    );
    expect(
      rows.map((r) => r['type']).toSet(),
      {'water', 'fertilize'},
    );
  });

  group('care events', () {
    late CareEventLocalDataSource eventSource;

    setUp(() {
      eventSource = CareEventLocalDataSourceImpl(db);
    });

    CareEventModel buildEvent({
      required String id,
      String plantId = 'p1',
      String type = 'water',
      required DateTime completedAt,
    }) {
      return CareEventModel(
        id: id,
        plantId: plantId,
        type: type,
        completedAt: completedAt,
        source: CareEventSource.home,
      );
    }

    test('insert and read back events, most recent first', () async {
      await eventSource.insertEvent(
        buildEvent(id: 'e1', completedAt: DateTime(2026, 7, 20, 9)),
      );
      await eventSource.insertEvent(
        buildEvent(id: 'e2', completedAt: DateTime(2026, 7, 22, 9)),
      );

      final events = await eventSource.getEventsForPlant('p1');

      expect(events.map((e) => e.id).toList(), ['e2', 'e1']);
      expect(events.first.source, CareEventSource.home);
    });

    test('latest per plant and type groups both dimensions', () async {
      await eventSource.insertEvent(
        buildEvent(id: 'w1', plantId: 'pa', completedAt: DateTime(2026, 7, 18)),
      );
      await eventSource.insertEvent(
        buildEvent(id: 'w2', plantId: 'pa', completedAt: DateTime(2026, 7, 21)),
      );
      await eventSource.insertEvent(
        buildEvent(
          id: 'f1',
          plantId: 'pa',
          type: 'fertilize',
          completedAt: DateTime(2026, 7, 10),
        ),
      );

      final latest = await eventSource.getLatestByPlantAndType();

      expect(latest['pa']!['water'], DateTime(2026, 7, 21));
      expect(latest['pa']!['fertilize'], DateTime(2026, 7, 10));
    });

    test('rejects events missing id, plant, or type', () async {
      expect(
        () => eventSource.insertEvent(
          buildEvent(id: '', completedAt: DateTime(2026, 7, 22)),
        ),
        throwsArgumentError,
      );
    });
  });

  group('schema migrations from v3', () {
    const v3PlantTable = '''
CREATE TABLE plants(
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  age_months INTEGER,
  description TEXT,
  origin TEXT,
  soil_type TEXT,
  preferred_lighting TEXT,
  watering_level TEXT,
  scientific_name TEXT,
  image_paths TEXT,
  use_random_image INTEGER NOT NULL DEFAULT 0
);
''';
    const v3ReminderTable = '''
CREATE TABLE watering_reminders(
  id TEXT PRIMARY KEY,
  plant_id TEXT NOT NULL,
  frequency_days INTEGER NOT NULL,
  weekdays TEXT,
  preferred_time TEXT,
  notes TEXT,
  FOREIGN KEY(plant_id) REFERENCES plants(id) ON DELETE CASCADE
);
''';

    late Database legacy;

    setUp(() async {
      // A private in-memory instance — the shared :memory: one already holds
      // the v4 schema from the outer setUp.
      legacy = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await legacy.execute(v3PlantTable);
      await legacy.execute(v3ReminderTable);
      await legacy.insert('plants', {'id': 'p1', 'name': 'Ficus'});
      await legacy.insert('watering_reminders', {
        'id': 'r-weekly',
        'plant_id': 'p1',
        'frequency_days': 7,
        'weekdays': '[1,3,5]',
        'preferred_time': '2026-01-01T08:30:00.000',
        'notes': 'Morning water',
      });
      await legacy.insert('watering_reminders', {
        'id': 'r-interval',
        'plant_id': 'p1',
        'frequency_days': 14,
        'weekdays': null,
      });
    });

    tearDown(() async {
      await legacy.close();
    });

    test('v3 to v4 moves reminders into care_tasks and drops old table',
        () async {
      await AppDatabase.migrate(legacy, 3, AppDatabase.version);

      final tasks = await legacy.query('care_tasks');
      expect(tasks.length, 2);
      final byId = {for (final t in tasks) t['id']: t};
      expect(byId['r-weekly']!['type'], 'water');
      expect(byId['r-weekly']!['schedule_type'], 'weekly');
      expect(byId['r-weekly']!['weekdays'], '[1,3,5]');
      expect(byId['r-weekly']!['preferred_time'], '2026-01-01T08:30:00.000');
      expect(byId['r-weekly']!['notes'], 'Morning water');
      expect(byId['r-interval']!['schedule_type'], 'interval');
      expect(byId['r-interval']!['interval_days'], 14);

      final oldTable = await legacy.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='watering_reminders'",
      );
      expect(oldTable, isEmpty);
    });

    test('migrated data is readable through the data source', () async {
      await AppDatabase.migrate(legacy, 3, AppDatabase.version);

      final ds = PlantLocalDataSourceImpl(legacy);
      final plant = await ds.getPlant('p1');

      expect(plant, isNotNull);
      expect(plant!.reminders.length, 2);
      final weekly =
          plant.reminders.firstWhere((r) => r.id == 'r-weekly');
      expect(weekly.weekdays, [1, 3, 5]);
      expect(weekly.preferredTime, DateTime(2026, 1, 1, 8, 30));
      final interval =
          plant.reminders.firstWhere((r) => r.id == 'r-interval');
      expect(interval.frequencyDays, 14);
    });

    test('v4 adds rooms, care_events, and plants.room_id', () async {
      await AppDatabase.migrate(legacy, 3, AppDatabase.version);

      await legacy.insert('rooms', {'id': 'room-1', 'name': 'Balcony'});
      await legacy.update(
        'plants',
        {'room_id': 'room-1'},
        where: 'id = ?',
        whereArgs: ['p1'],
      );
      await legacy.insert('care_events', {
        'id': 'ev-1',
        'plant_id': 'p1',
        'type': 'water',
        'completed_at': '2026-07-22T09:00:00.000',
        'source': 'manual',
      });

      final plants = await legacy.query('plants');
      expect(plants.first['room_id'], 'room-1');
      final events = await legacy.query('care_events');
      expect(events.length, 1);
    });

    test('v6 adds created_at and backfills existing tasks', () async {
      await AppDatabase.migrate(legacy, 3, AppDatabase.version);

      final tasks = await legacy.query('care_tasks');
      expect(tasks, isNotEmpty);
      // Backfilled rather than left null, so migrated tasks start clean
      // instead of inheriting a phantom overdue state.
      for (final task in tasks) {
        expect(task['created_at'], isNotNull);
        expect(DateTime.tryParse(task['created_at'] as String), isNotNull);
      }
    });

    test('v5 canonicalizes recognizable care text into enum names', () async {
      await legacy.insert('plants', {
        'id': 'p-canonical',
        'name': 'Fig',
        'preferred_lighting': 'Bright indirect',
        'watering_level': 'Moderate',
        'soil_type': 'Loamy soil',
      });

      await AppDatabase.migrate(legacy, 3, AppDatabase.version);

      final row = (await legacy.query(
        'plants',
        where: 'id = ?',
        whereArgs: ['p-canonical'],
      ))
          .single;
      expect(row['preferred_lighting'], 'brightIndirect');
      expect(row['watering_level'], 'moderate');
      expect(row['soil_type'], 'allPurpose');
      expect(row['care_notes'], isNull);
    });

    test('v5 preserves unmatched care text in care_notes', () async {
      await legacy.insert('plants', {
        'id': 'p-fuzzy',
        'name': 'Mystery Plant',
        'preferred_lighting': 'East window vibes',
        'watering_level': 'whenever I remember',
      });

      await AppDatabase.migrate(legacy, 3, AppDatabase.version);

      final row = (await legacy.query(
        'plants',
        where: 'id = ?',
        whereArgs: ['p-fuzzy'],
      ))
          .single;
      expect(row['preferred_lighting'], isNull);
      expect(row['watering_level'], isNull);
      expect(
        row['care_notes'],
        'East window vibes\nwhenever I remember',
      );
    });
  });

  group('plant image store', () {
    Future<File> createSourceImage(String name) async {
      final file = File(p.join(sourceDir.path, name));
      await file.writeAsBytes([1, 2, 3]);
      return file;
    }

    test('upsert copies external images into app-owned storage', () async {
      final source = await createSourceImage('cache_photo.jpg');
      final plant = Plant(
        id: 'plant-img',
        name: 'Calathea',
        imagePaths: [source.path],
      );

      await repository.upsertPlant(plant);
      final loaded = await repository.getPlant('plant-img');

      expect(loaded!.imagePaths.length, 1);
      final storedPath = loaded.imagePaths.first;
      expect(p.isWithin(imageBaseDir.path, storedPath), isTrue);
      expect(await File(storedPath).exists(), isTrue);

      // Losing the original (cache eviction) must not affect the stored copy.
      await source.delete();
      expect(await File(storedPath).exists(), isTrue);
    });

    test('already-persisted paths pass through unchanged on re-save', () async {
      final source = await createSourceImage('cache_photo2.jpg');
      final plant = Plant(
        id: 'plant-img2',
        name: 'Fern',
        imagePaths: [source.path],
      );

      await repository.upsertPlant(plant);
      final first = (await repository.getPlant('plant-img2'))!.imagePaths;
      await repository.upsertPlant(
        Plant(id: 'plant-img2', name: 'Fern', imagePaths: first),
      );
      final second = (await repository.getPlant('plant-img2'))!.imagePaths;

      expect(second, first);
    });

    test('removing an image on edit deletes its stored file', () async {
      final a = await createSourceImage('a.jpg');
      final b = await createSourceImage('b.jpg');
      await repository.upsertPlant(Plant(
        id: 'plant-img3',
        name: 'Ivy',
        imagePaths: [a.path, b.path],
      ));
      final stored = (await repository.getPlant('plant-img3'))!.imagePaths;
      expect(stored.length, 2);

      await repository.upsertPlant(Plant(
        id: 'plant-img3',
        name: 'Ivy',
        imagePaths: [stored.first],
      ));

      expect(await File(stored.first).exists(), isTrue);
      expect(await File(stored.last).exists(), isFalse);
    });

    test('deleting a plant removes its image directory', () async {
      final source = await createSourceImage('c.jpg');
      await repository.upsertPlant(Plant(
        id: 'plant-img4',
        name: 'Palm',
        imagePaths: [source.path],
      ));
      final stored = (await repository.getPlant('plant-img4'))!.imagePaths;

      await repository.deletePlant('plant-img4');

      expect(await File(stored.first).exists(), isFalse);
      expect(
        await Directory(p.join(imageBaseDir.path, 'plant-img4')).exists(),
        isFalse,
      );
    });
  });
}
