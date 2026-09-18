import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:water_it/core/database/app_database.dart';
import 'package:water_it/features/backup/data/backup_service.dart';
import 'package:water_it/features/plants/data/datasources/plant_image_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late Directory imagesDir;
  late PlantImageStore imageStore;
  late BackupService service;

  Future<Database> openDb() => databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'settings_notify_daily_summary': true,
      'settings_temperature_unit': 'fahrenheit',
    });
    db = await openDb();
    await AppDatabase.createSchema(db);
    imagesDir = await Directory.systemTemp.createTemp('backup_images');
    imageStore = PlantImageStoreImpl(imagesDir);
    service = BackupService(db, imageStore);
  });

  tearDown(() async {
    await db.close();
    if (await imagesDir.exists()) {
      await imagesDir.delete(recursive: true);
    }
  });

  Future<String> seedData() async {
    // A stored plant photo, exactly where PlantImageStore would put it.
    final plantDir = Directory(p.join(imagesDir.path, 'p1'));
    await plantDir.create(recursive: true);
    final imagePath = p.join(plantDir.path, 'photo-1.jpg');
    await File(imagePath).writeAsBytes([10, 20, 30, 40]);

    await db.insert('rooms',
        {'id': 'r1', 'name': 'Balcony', 'is_outdoor': 1, 'sort_order': 0});
    await db.insert('plants', {
      'id': 'p1',
      'name': 'Monstera',
      'room_id': 'r1',
      'preferred_lighting': 'brightIndirect',
      'care_notes': 'Wipe leaves',
      'image_paths': jsonEncode([imagePath]),
      'use_random_image': 0,
    });
    await db.insert('plants', {
      'id': 'p2',
      'name': 'Basil',
      'image_paths': jsonEncode(<String>[]),
      'use_random_image': 0,
    });
    await db.insert('care_tasks', {
      'id': 't1',
      'plant_id': 'p1',
      'type': 'water',
      'schedule_type': 'weekly',
      'weekdays': '[1,4]',
      'interval_days': 0,
      'active': 1,
    });
    await db.insert('care_events', {
      'id': 'e1',
      'plant_id': 'p1',
      'task_id': 't1',
      'type': 'water',
      'completed_at': '2026-08-01T09:00:00.000',
      'source': 'home',
    });
    return imagePath;
  }

  test('summary reports the zip contents', () async {
    await seedData();
    final bytes = await service.exportArchive();

    final summary = BackupService.readSummary(bytes)!;

    expect(summary.format, BackupService.formatVersion);
    expect(summary.plantCount, 2);
    expect(summary.roomCount, 1);
    expect(summary.careTaskCount, 1);
    expect(summary.careEventCount, 1);
    expect(summary.imageCount, 1);
  });

  test('export → wipe → import loses nothing, even on a "new device"',
      () async {
    await seedData();
    final bytes = await service.exportArchive();

    // Fresh database and a different images directory = new device.
    final newDb = await openDb();
    await AppDatabase.createSchema(newDb);
    final newImagesDir = await Directory.systemTemp.createTemp('backup_new');
    SharedPreferences.setMockInitialValues({});
    final newService =
        BackupService(newDb, PlantImageStoreImpl(newImagesDir));

    try {
      await newService.importArchive(bytes);

      final plants = await newDb.query('plants', orderBy: 'id');
      expect(plants.length, 2);
      expect(plants.first['name'], 'Monstera');
      expect(plants.first['room_id'], 'r1');
      expect(plants.first['preferred_lighting'], 'brightIndirect');
      expect(plants.first['care_notes'], 'Wipe leaves');

      // The photo was restored into the NEW images dir and the path rewritten.
      final restoredPaths = List<String>.from(
          jsonDecode(plants.first['image_paths'] as String) as List<dynamic>);
      expect(restoredPaths.length, 1);
      expect(p.isWithin(newImagesDir.path, restoredPaths.single), isTrue);
      expect(
        await File(restoredPaths.single).readAsBytes(),
        [10, 20, 30, 40],
      );

      expect((await newDb.query('rooms')).single['name'], 'Balcony');
      expect((await newDb.query('care_tasks')).single['weekdays'], '[1,4]');
      expect(
        (await newDb.query('care_events')).single['completed_at'],
        '2026-08-01T09:00:00.000',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_notify_daily_summary'), isTrue);
      expect(prefs.getString('settings_temperature_unit'), 'fahrenheit');
    } finally {
      await newDb.close();
      await newImagesDir.delete(recursive: true);
    }
  });

  test('import replaces existing data instead of merging', () async {
    await seedData();
    final bytes = await service.exportArchive();

    await db.insert('plants', {
      'id': 'p-extra',
      'name': 'Should disappear',
      'image_paths': '[]',
      'use_random_image': 0,
    });

    await service.importArchive(bytes);

    final names =
        (await db.query('plants')).map((r) => r['name']).toSet();
    expect(names, {'Monstera', 'Basil'});
  });

  test('rejects a backup from a newer app version', () async {
    final archive = Archive();
    final data = utf8.encode(jsonEncode({'format': 999, 'plants': []}));
    archive.addFile(ArchiveFile('data.json', data.length, data));
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

    expect(
      () => service.importArchive(bytes),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains('newer version'),
      )),
    );
  });

  test('readSummary returns null for garbage input', () {
    expect(BackupService.readSummary(Uint8List.fromList([1, 2, 3])), isNull);

    final archive = Archive();
    final data = utf8.encode('not json');
    archive.addFile(ArchiveFile('data.json', data.length, data));
    final zip = Uint8List.fromList(ZipEncoder().encode(archive)!);
    expect(BackupService.readSummary(zip), isNull);
  });
}
