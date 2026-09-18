import 'package:water_it/features/plants/domain/repositories/care_log_repository.dart';

class GetLatestWaterEvents {
  GetLatestWaterEvents(this._repository);

  final CareLogRepository _repository;

  Future<Map<String, DateTime>> call() {
    return _repository.getLatestWaterEvents();
  }
}
