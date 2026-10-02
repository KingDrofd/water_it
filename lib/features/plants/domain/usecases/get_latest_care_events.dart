import 'package:water_it/features/plants/domain/repositories/care_log_repository.dart';

/// Latest completion per plant per task type: plantId -> type -> timestamp.
class GetLatestCareEvents {
  GetLatestCareEvents(this._repository);

  final CareLogRepository _repository;

  Future<Map<String, Map<String, DateTime>>> call() =>
      _repository.getLatestEvents();
}
