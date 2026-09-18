import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:water_it/core/database/app_database.dart';
import 'package:water_it/features/plants/data/datasources/plant_local_data_source.dart';
import 'package:water_it/features/plants/data/datasources/room_local_data_source.dart';
import 'package:water_it/features/plants/data/models/plant_model.dart';
import 'package:water_it/features/plants/data/models/room_model.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late RoomLocalDataSource roomSource;
  late PlantLocalDataSource plantSource;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await AppDatabase.createSchema(db);
    roomSource = RoomLocalDataSourceImpl(db);
    plantSource = PlantLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  test('rooms round-trip and come back in sort order', () async {
    await roomSource.upsertRoom(
      const RoomModel(id: 'r2', name: 'Balcony', isOutdoor: true, sortOrder: 1),
    );
    await roomSource.upsertRoom(
      const RoomModel(id: 'r1', name: 'Living room', sortOrder: 0),
    );

    final rooms = await roomSource.getRooms();

    expect(rooms.map((r) => r.id).toList(), ['r1', 'r2']);
    expect(rooms.first.isOutdoor, isFalse);
    expect(rooms.last.isOutdoor, isTrue);
  });

  test('plant keeps its room through a save/load round-trip', () async {
    await roomSource.upsertRoom(
      const RoomModel(id: 'r1', name: 'Living room'),
    );
    await plantSource.upsertPlant(
      const PlantModel(id: 'p1', name: 'Monstera', roomId: 'r1'),
    );

    final loaded = await plantSource.getPlant('p1');

    expect(loaded!.roomId, 'r1');
  });

  test('deleting a room unassigns its plants but keeps them', () async {
    await roomSource.upsertRoom(
      const RoomModel(id: 'r1', name: 'Living room'),
    );
    await plantSource.upsertPlant(
      const PlantModel(id: 'p1', name: 'Monstera', roomId: 'r1'),
    );

    await roomSource.deleteRoom('r1');

    expect(await roomSource.getRooms(), isEmpty);
    final plant = await plantSource.getPlant('p1');
    expect(plant, isNotNull);
    expect(plant!.roomId, isNull);
  });

  test('rejects a room with empty id or name', () async {
    expect(
      () => roomSource.upsertRoom(const RoomModel(id: '', name: 'X')),
      throwsArgumentError,
    );
    expect(
      () => roomSource.upsertRoom(const RoomModel(id: 'r1', name: '  ')),
      throwsArgumentError,
    );
  });
}
