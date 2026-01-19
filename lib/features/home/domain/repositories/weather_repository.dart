import 'package:water_it/features/home/domain/entities/weather_slot.dart';

abstract class WeatherRepository {
  Future<List<WeatherSlot>> getTodaySlots({
    required double lat,
    required double lon,
  });
}
