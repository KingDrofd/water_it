import 'package:water_it/features/plants/domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.name,
    super.isOutdoor,
    super.sortOrder,
  });

  factory RoomModel.fromEntity(Room room) {
    return RoomModel(
      id: room.id,
      name: room.name,
      isOutdoor: room.isOutdoor,
      sortOrder: room.sortOrder,
    );
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] as String,
      name: map['name'] as String,
      isOutdoor: (map['is_outdoor'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_outdoor': isOutdoor ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
}
