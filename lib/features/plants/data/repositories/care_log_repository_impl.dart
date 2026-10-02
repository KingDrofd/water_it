import 'package:water_it/features/plants/data/datasources/care_event_local_data_source.dart';
import 'package:water_it/features/plants/data/models/care_event_model.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/repositories/care_log_repository.dart';

class CareLogRepositoryImpl implements CareLogRepository {
  CareLogRepositoryImpl(this._localDataSource);

  final CareEventLocalDataSource _localDataSource;

  @override
  Future<void> logEvent(CareEvent event) {
    return _localDataSource.insertEvent(CareEventModel.fromEntity(event));
  }

  @override
  Future<List<CareEvent>> getEventsForPlant(String plantId) {
    return _localDataSource.getEventsForPlant(plantId);
  }

  @override
  Future<Map<String, Map<String, DateTime>>> getLatestEvents() {
    return _localDataSource.getLatestByPlantAndType();
  }
}
