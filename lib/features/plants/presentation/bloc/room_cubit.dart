import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/usecases/delete_room.dart';
import 'package:water_it/features/plants/domain/usecases/get_rooms.dart';
import 'package:water_it/features/plants/domain/usecases/save_room.dart';

enum RoomStatus { initial, loading, loaded, failure }

class RoomState extends Equatable {
  const RoomState({
    this.status = RoomStatus.initial,
    this.rooms = const [],
    this.errorMessage,
  });

  final RoomStatus status;
  final List<Room> rooms;
  final String? errorMessage;

  RoomState copyWith({
    RoomStatus? status,
    List<Room>? rooms,
    String? errorMessage,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rooms, errorMessage];
}

class RoomCubit extends Cubit<RoomState> {
  RoomCubit(this._getRooms, this._saveRoom, this._deleteRoom)
      : super(const RoomState());

  final GetRooms _getRooms;
  final SaveRoom _saveRoom;
  final DeleteRoom _deleteRoom;

  Future<void> load() async {
    emit(state.copyWith(status: RoomStatus.loading, errorMessage: null));
    try {
      final rooms = await _getRooms();
      emit(state.copyWith(status: RoomStatus.loaded, rooms: rooms));
    } catch (error) {
      emit(
        state.copyWith(
          status: RoomStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> save(Room room) async {
    try {
      await _saveRoom(room);
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return;
    }
    await load();
  }

  Future<void> delete(String id) async {
    try {
      await _deleteRoom(id);
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
      return;
    }
    await load();
  }

  /// Persists a new manual order (list index becomes sort order).
  Future<void> reorder(List<Room> ordered) async {
    emit(state.copyWith(rooms: ordered));
    try {
      for (var i = 0; i < ordered.length; i++) {
        if (ordered[i].sortOrder != i) {
          await _saveRoom(ordered[i].copyWith(sortOrder: i));
        }
      }
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
    await load();
  }
}
