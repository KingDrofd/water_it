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
      version: 1,
      onCreate: (db, version) async {
        await db.execute(PlantLocalDataSourceImpl.createPlantTable);
        await db.execute(PlantLocalDataSourceImpl.createReminderTable);
      },
    );
  }
}
