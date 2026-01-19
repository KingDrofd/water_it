import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';

class AppDatabase {
  AppDatabase._();

  static Future<Database> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'water_it.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute(PlantLocalDataSourceImpl.createPlantTable);
        await db.execute(PlantLocalDataSourceImpl.createReminderTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE plants ADD COLUMN use_random_image INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE watering_reminders ADD COLUMN weekdays TEXT',
          );
        }
      },
    );
  }
}
