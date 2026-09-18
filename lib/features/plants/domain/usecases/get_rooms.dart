import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/repositories/room_repository.dart';

class GetRooms {
  GetRooms(this._repository);

  final RoomRepository _repository;

  Future<List<Room>> call() => _repository.getRooms();
}
