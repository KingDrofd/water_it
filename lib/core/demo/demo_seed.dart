import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/entities/care_profile.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/usecases/delete_plant.dart';
import 'package:water_it/features/plants/domain/usecases/delete_room.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';
import 'package:water_it/features/plants/domain/usecases/get_rooms.dart';
import 'package:water_it/features/plants/domain/usecases/log_care_event.dart';
import 'package:water_it/features/plants/domain/usecases/save_care_task.dart';
import 'package:water_it/features/plants/domain/usecases/save_room.dart';
import 'package:water_it/features/plants/domain/usecases/upsert_plant.dart';

/// Replaces the database contents with a fixed demo library, for store and
/// marketing screenshots.
///
/// Off unless built with `--dart-define=SEED_DEMO=true`, so the code path
/// never runs for a real user even though it ships in the binary.
const bool kSeedDemoData = bool.fromEnvironment('SEED_DEMO');

const _uuid = Uuid();

/// Days since the last completion of each plant's watering task, chosen
/// against its interval so the screenshots show every state at once: one
/// plant overdue, two due today, the rest comfortably upcoming.
Future<void> seedDemoData() async {
  if (!kSeedDemoData) {
    return;
  }
  final now = DateTime.now();

  await _wipe();
  final images = await _unpackPhotos();

  final livingRoom = Room(id: _uuid.v4(), name: 'Living room');
  final bedroom = Room(id: _uuid.v4(), name: 'Bedroom', sortOrder: 1);
  final balcony = Room(
    id: _uuid.v4(),
    name: 'Balcony',
    isOutdoor: true,
    sortOrder: 2,
  );

  final saveRoom = getIt<SaveRoom>();
  for (final room in [livingRoom, bedroom, balcony]) {
    await saveRoom(room);
  }

  // A task that predates every due moment we care about, so nothing is
  // treated as newly created and therefore exempt from being overdue.
  final createdAt = now.subtract(const Duration(days: 120));

  await _seedPlant(
    photo: images['monstera'],
    plant: Plant(
      id: _uuid.v4(),
      name: 'Monstera',
      scientificName: 'Monstera deliciosa',
      roomId: livingRoom.id,
      ageMonths: 18,
      description: 'Grown from a single cutting. Two new leaves this spring.',
      preferredLighting: LightingLevel.brightIndirect,
      wateringLevel: WateringLevel.moderate,
      soilType: SoilKind.allPurpose,
      origin: 'Southern Mexico',
      careNotes: 'Wipe the leaves monthly — it sulks when they get dusty.',
    ),
    tasks: [
      // Watered exactly one interval ago: due today.
      _interval(CareTaskType.water, 7, createdAt, lastDoneDaysAgo: 7),
      _interval(CareTaskType.fertilize, 30, createdAt, lastDoneDaysAgo: 26),
    ],
    now: now,
  );

  await _seedPlant(
    photo: images['peace_lily'],
    plant: Plant(
      id: _uuid.v4(),
      name: 'Peace lily',
      scientificName: 'Spathiphyllum wallisii',
      roomId: bedroom.id,
      ageMonths: 20,
      description: 'Droops dramatically the moment it is thirsty.',
      preferredLighting: LightingLevel.mediumIndirect,
      wateringLevel: WateringLevel.frequent,
      soilType: SoilKind.allPurpose,
    ),
    tasks: [
      // Two days past its due day: the overdue card.
      _interval(CareTaskType.water, 3, createdAt, lastDoneDaysAgo: 5),
      _interval(CareTaskType.prune, 60, createdAt, lastDoneDaysAgo: 10),
    ],
    now: now,
  );

  await _seedPlant(
    photo: images['aloe'],
    plant: Plant(
      id: _uuid.v4(),
      name: 'Aloe vera',
      scientificName: 'Aloe barbadensis',
      roomId: balcony.id,
      ageMonths: 14,
      description: 'Lives outside from May to September.',
      preferredLighting: LightingLevel.fullSun,
      wateringLevel: WateringLevel.low,
      soilType: SoilKind.cactusMix,
      careNotes: 'Bring indoors before the first frost.',
    ),
    tasks: [
      _interval(CareTaskType.water, 14, createdAt, lastDoneDaysAgo: 14),
      _interval(CareTaskType.repot, 365, createdAt, lastDoneDaysAgo: 200),
    ],
    now: now,
  );

  await _seedPlant(
    photo: images['pothos'],
    plant: Plant(
      id: _uuid.v4(),
      name: 'Golden pothos',
      scientificName: 'Epipremnum aureum',
      roomId: livingRoom.id,
      ageMonths: 24,
      description: 'Trailing along the top of the bookshelf.',
      preferredLighting: LightingLevel.mediumIndirect,
      wateringLevel: WateringLevel.moderate,
      soilType: SoilKind.allPurpose,
      origin: 'French Polynesia',
    ),
    tasks: [
      _interval(CareTaskType.water, 7, createdAt, lastDoneDaysAgo: 2),
    ],
    now: now,
  );

  await _seedPlant(
    photo: images['fiddle_leaf_fig'],
    plant: Plant(
      id: _uuid.v4(),
      name: 'Fiddle leaf fig',
      scientificName: 'Ficus lyrata',
      roomId: livingRoom.id,
      ageMonths: 30,
      description: 'Rotated a quarter turn each week so it grows straight.',
      preferredLighting: LightingLevel.brightIndirect,
      wateringLevel: WateringLevel.moderate,
      soilType: SoilKind.wellDraining,
    ),
    tasks: [
      _interval(CareTaskType.water, 7, createdAt, lastDoneDaysAgo: 3),
      // A weekly task, so the detail page shows both schedule kinds.
      _weekly(CareTaskType.mist, const [1, 4], createdAt, now),
    ],
    now: now,
  );

  await _seedPlant(
    photo: images['snake_plant'],
    plant: Plant(
      id: _uuid.v4(),
      name: 'Snake plant',
      scientificName: 'Sansevieria trifasciata',
      roomId: bedroom.id,
      ageMonths: 36,
      description: 'The one plant that forgives a holiday.',
      preferredLighting: LightingLevel.lowLight,
      wateringLevel: WateringLevel.low,
      soilType: SoilKind.wellDraining,
    ),
    tasks: [
      _interval(CareTaskType.water, 21, createdAt, lastDoneDaysAgo: 4),
    ],
    now: now,
  );

  debugPrint('Demo data seeded: 6 plants, 3 rooms.');
}

/// An interval task plus how long ago it was last completed, carried
/// together so [_seedPlant] can write the matching care events.
class _SeededTask {
  const _SeededTask(this.task, this.lastDoneDaysAgo);

  final CareTask task;
  final int? lastDoneDaysAgo;
}

_SeededTask _interval(
  CareTaskType type,
  int intervalDays,
  DateTime createdAt, {
  required int lastDoneDaysAgo,
}) {
  return _SeededTask(
    CareTask(
      id: _uuid.v4(),
      // Filled in by _seedPlant once the plant id exists.
      plantId: '',
      type: type,
      scheduleType: CareScheduleType.interval,
      intervalDays: intervalDays,
      preferredTime: DateTime(2026, 1, 1, 9, 0),
      createdAt: createdAt,
    ),
    lastDoneDaysAgo,
  );
}

/// A weekly task, last completed on its most recent scheduled day that has
/// already passed — so it reads as kept up rather than missed.
_SeededTask _weekly(
  CareTaskType type,
  List<int> weekdays,
  DateTime createdAt,
  DateTime now,
) {
  var lastDone = 1;
  for (var back = 1; back <= 7; back++) {
    if (weekdays.contains(((now.weekday - back - 1) % 7) + 1)) {
      lastDone = back;
      break;
    }
  }
  return _SeededTask(
    CareTask(
      id: _uuid.v4(),
      plantId: '',
      type: type,
      scheduleType: CareScheduleType.weekly,
      weekdays: weekdays,
      preferredTime: DateTime(2026, 1, 1, 8, 30),
      createdAt: createdAt,
    ),
    lastDone,
  );
}

/// Saves the plant, its tasks, and a short completion history for each —
/// two or three past events so the care log and "last done" lines aren't
/// empty in screenshots.
Future<void> _seedPlant({
  required Plant plant,
  required List<_SeededTask> tasks,
  required DateTime now,
  String? photo,
}) async {
  await getIt<UpsertPlant>()(
    plant.copyWith(imagePaths: photo == null ? const [] : [photo]),
  );

  final saveTask = getIt<SaveCareTask>();
  final logEvent = getIt<LogCareEvent>();

  for (final seeded in tasks) {
    final task = seeded.task.copyWith(plantId: plant.id);
    await saveTask(task);

    final lastDone = seeded.lastDoneDaysAgo;
    if (lastDone == null) {
      continue;
    }
    // Three completions spaced by the task's own cadence, so the history
    // reads like a plant that has actually been cared for.
    final step = task.scheduleType == CareScheduleType.interval
        ? task.intervalDays
        : 7;
    for (var i = 0; i < 3; i++) {
      final at = now.subtract(Duration(days: lastDone + step * i));
      await logEvent(
        CareEvent(
          id: _uuid.v4(),
          plantId: plant.id,
          taskId: task.id,
          type: task.type.name,
          completedAt: DateTime(at.year, at.month, at.day, 9, 12),
          source: CareEventSource.detail,
        ),
      );
    }
  }
}

/// Clears every plant and room, so re-running the seed replaces the library
/// instead of stacking a second copy on top of it.
Future<void> _wipe() async {
  final deletePlant = getIt<DeletePlant>();
  for (final plant in await getIt<GetPlants>()()) {
    await deletePlant(plant.id);
  }
  final deleteRoom = getIt<DeleteRoom>();
  for (final room in await getIt<GetRooms>()()) {
    await deleteRoom(room.id);
  }
}

/// Copies the bundled demo photos out to real files, because the plant
/// repository persists images by reading them off disk.
Future<Map<String, String>> _unpackPhotos() async {
  const names = [
    'monstera',
    'snake_plant',
    'pothos',
    'fiddle_leaf_fig',
    'aloe',
    'peace_lily',
  ];
  final dir = Directory(
    p.join((await getTemporaryDirectory()).path, 'demo_seed'),
  );
  await dir.create(recursive: true);

  final result = <String, String>{};
  for (final name in names) {
    final data = await rootBundle.load('assets/demo/$name.jpg');
    final file = File(p.join(dir.path, '$name.jpg'));
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    result[name] = file.path;
  }
  return result;
}
