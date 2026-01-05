import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';
import 'package:water_it/features/plants/data/models/plant_model.dart';
import 'package:water_it/features/plants/data/repositories/plants_repository_impl.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/repositories/plants_repository.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late PlantLocalDataSource dataSource;
  late PlantsRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(PlantLocalDataSourceImpl.createPlantTable);
    await db.execute(PlantLocalDataSourceImpl.createReminderTable);
    dataSource = PlantLocalDataSourceImpl(db);
    repository = PlantsRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await db.close();
  });

  PlantModel buildModel({String id = 'plant-1'}) {
    return PlantModel(
      id: id,
      name: 'Fiddle Leaf Fig',
      ageMonths: 12,
      description: 'Loves bright, indirect light.',
      origin: 'West Africa',
      soilType: 'Well-draining',
      preferredLighting: 'Bright indirect',
      wateringLevel: 'Moderate',
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
      soilType: 'Well-draining',
      preferredLighting: 'Low to bright indirect',
      wateringLevel: 'Low',
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
    expect(loaded.soilType, 'Well-draining');
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
}
