import 'package:water_it/features/plants/data/datasources/room_local_data_source.dart';
import 'package:water_it/features/plants/data/models/room_model.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  RoomRepositoryImpl(this._localDataSource);

  final RoomLocalDataSource _localDataSource;

  @override
  Future<List<Room>> getRooms() => _localDataSource.getRooms();

  @override
  Future<void> saveRoom(Room room) =>
      _localDataSource.upsertRoom(RoomModel.fromEntity(room));

  @override
  Future<void> deleteRoom(String id) => _localDataSource.deleteRoom(id);
}
