import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/repositories/care_log_repository.dart';

class GetCareEvents {
  GetCareEvents(this._repository);

  final CareLogRepository _repository;

  Future<List<CareEvent>> call(String plantId) {
    return _repository.getEventsForPlant(plantId);
  }
}
