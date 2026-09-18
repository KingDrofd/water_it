import 'package:water_it/features/plants/domain/entities/room.dart';

abstract class RoomRepository {
  /// All rooms in sort order.
  Future<List<Room>> getRooms();

  Future<void> saveRoom(Room room);

  /// Deletes the room; plants assigned to it become unassigned.
  Future<void> deleteRoom(String id);
}
