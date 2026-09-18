import 'package:water_it/features/plants/domain/repositories/room_repository.dart';

class DeleteRoom {
  DeleteRoom(this._repository);

  final RoomRepository _repository;

  Future<void> call(String id) => _repository.deleteRoom(id);
}
