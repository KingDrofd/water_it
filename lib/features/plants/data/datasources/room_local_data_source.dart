import 'package:sqflite/sqflite.dart';
import 'package:water_it/features/plants/data/models/room_model.dart';

abstract class RoomLocalDataSource {
  Future<List<RoomModel>> getRooms();
  Future<void> upsertRoom(RoomModel room);
  Future<void> deleteRoom(String id);
}

class RoomLocalDataSourceImpl implements RoomLocalDataSource {
  RoomLocalDataSourceImpl(this.db);

  final Database db;

  @override
  Future<List<RoomModel>> getRooms() async {
    final rows = await db.query('rooms', orderBy: 'sort_order, name');
    return rows.map(RoomModel.fromMap).toList();
  }

  @override
  Future<void> upsertRoom(RoomModel room) async {
    if (room.id.trim().isEmpty || room.name.trim().isEmpty) {
      throw ArgumentError('Room id and name are required');
    }
    await db.insert(
      'rooms',
      room.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteRoom(String id) async {
    await db.transaction((txn) async {
      // Foreign keys aren't enforced by default — unassign manually.
      await txn.update(
        'plants',
        {'room_id': null},
        where: 'room_id = ?',
        whereArgs: [id],
      );
      await txn.delete('rooms', where: 'id = ?', whereArgs: [id]);
    });
  }
}
