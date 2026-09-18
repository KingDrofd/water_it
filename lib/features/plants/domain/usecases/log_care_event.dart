import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/repositories/care_log_repository.dart';

class LogCareEvent {
  LogCareEvent(this._repository);

  final CareLogRepository _repository;

  Future<void> call(CareEvent event) {
    return _repository.logEvent(event);
  }
}
