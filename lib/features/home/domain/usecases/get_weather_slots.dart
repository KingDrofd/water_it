import 'package:water_it/features/home/domain/entities/weather_slot.dart';
import 'package:water_it/features/home/domain/repositories/weather_repository.dart';

class GetWeatherSlots {
  GetWeatherSlots(this._repository);

  final WeatherRepository _repository;

  Future<List<WeatherSlot>> call({
    required double lat,
    required double lon,
  }) {
    return _repository.getTodaySlots(lat: lat, lon: lon);
  }
}
