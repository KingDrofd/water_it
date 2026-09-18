import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/repositories/room_repository.dart';

class SaveRoom {
  SaveRoom(this._repository);

  final RoomRepository _repository;

  Future<void> call(Room room) => _repository.saveRoom(room);
}
