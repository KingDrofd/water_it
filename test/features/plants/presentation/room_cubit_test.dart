import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/usecases/delete_room.dart';
import 'package:water_it/features/plants/domain/usecases/get_rooms.dart';
import 'package:water_it/features/plants/domain/usecases/save_room.dart';
import 'package:water_it/features/plants/presentation/bloc/room_cubit.dart';

class MockGetRooms extends Mock implements GetRooms {}

class MockSaveRoom extends Mock implements SaveRoom {}

class MockDeleteRoom extends Mock implements DeleteRoom {}

void main() {
  late MockGetRooms getRooms;
  late MockSaveRoom saveRoom;
  late MockDeleteRoom deleteRoom;
  late RoomCubit cubit;

  setUpAll(() {
    registerFallbackValue(const Room(id: 'f', name: 'f'));
  });

  setUp(() {
    getRooms = MockGetRooms();
    saveRoom = MockSaveRoom();
    deleteRoom = MockDeleteRoom();
    cubit = RoomCubit(getRooms, saveRoom, deleteRoom);
  });

  tearDown(() => cubit.close());

  const roomA = Room(id: 'a', name: 'Living room', sortOrder: 0);
  const roomB = Room(id: 'b', name: 'Balcony', isOutdoor: true, sortOrder: 1);

  test('load emits rooms', () async {
    when(() => getRooms()).thenAnswer((_) async => [roomA, roomB]);

    await cubit.load();

    expect(cubit.state.status, RoomStatus.loaded);
    expect(cubit.state.rooms, [roomA, roomB]);
  });

  test('save persists and reloads', () async {
    when(() => saveRoom(any())).thenAnswer((_) async {});
    when(() => getRooms()).thenAnswer((_) async => [roomA]);

    await cubit.save(roomA);

    verify(() => saveRoom(roomA)).called(1);
    expect(cubit.state.rooms, [roomA]);
  });

  test('delete removes and reloads', () async {
    when(() => deleteRoom('a')).thenAnswer((_) async {});
    when(() => getRooms()).thenAnswer((_) async => []);

    await cubit.delete('a');

    verify(() => deleteRoom('a')).called(1);
    expect(cubit.state.rooms, isEmpty);
  });

  test('reorder rewrites sort orders that changed', () async {
    when(() => saveRoom(any())).thenAnswer((_) async {});
    when(() => getRooms()).thenAnswer((_) async => [roomB, roomA]);

    // Move roomB (sortOrder 1) to the front.
    await cubit.reorder(const [roomB, roomA]);

    final saved =
        verify(() => saveRoom(captureAny())).captured.cast<Room>();
    expect(saved.length, 2); // both rooms' orders changed
    expect(saved.firstWhere((r) => r.id == 'b').sortOrder, 0);
    expect(saved.firstWhere((r) => r.id == 'a').sortOrder, 1);
  });

  test('load failure emits failure state', () async {
    when(() => getRooms()).thenThrow(Exception('boom'));

    await cubit.load();

    expect(cubit.state.status, RoomStatus.failure);
  });
}
