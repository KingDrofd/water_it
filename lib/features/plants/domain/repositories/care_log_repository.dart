import 'package:water_it/features/plants/domain/entities/care_event.dart';

abstract class CareLogRepository {
  Future<void> logEvent(CareEvent event);

  /// Events for one plant, most recent first.
  Future<List<CareEvent>> getEventsForPlant(String plantId);

  /// Latest completion per plant per task type: plantId -> type -> timestamp.
  /// Anchors interval schedules ("every N days from the last completion").
  Future<Map<String, Map<String, DateTime>>> getLatestEvents();
}
