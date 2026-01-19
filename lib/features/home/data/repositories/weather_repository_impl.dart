import 'package:water_it/features/home/data/datasources/open_weather_data_source.dart';
import 'package:water_it/features/home/data/models/weather_slot_model.dart';
import 'package:water_it/features/home/domain/entities/weather_slot.dart';
import 'package:water_it/features/home/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl(this._dataSource);

  final OpenWeatherDataSource _dataSource;

  @override
  Future<List<WeatherSlot>> getTodaySlots({
    required double lat,
    required double lon,
  }) async {
    final forecast = await _dataSource.fetchForecast(lat: lat, lon: lon);
    final now = DateTime.now();
    final upcoming = forecast.where((slot) => slot.time.isAfter(now)).toList();
    if (upcoming.isEmpty) {
      return _pickThreeSlots(forecast);
    }

    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todaySlots = upcoming.where((slot) {
      return slot.time.year == today.year &&
          slot.time.month == today.month &&
          slot.time.day == today.day;
    }).toList();

    if (todaySlots.length >= 3) {
      return _pickThreeSlots(todaySlots);
    }

    final tomorrowSlots = upcoming.where((slot) {
      return slot.time.year == tomorrow.year &&
          slot.time.month == tomorrow.month &&
          slot.time.day == tomorrow.day;
    }).toList();

    final combined = [
      ...todaySlots,
      ...tomorrowSlots,
    ];

    return _pickThreeSlots(combined);
  }

  List<WeatherSlotModel> _pickThreeSlots(List<WeatherSlotModel> slots) {
    if (slots.length <= 3) {
      return slots;
    }

    return [
      slots[0],
      slots[(slots.length / 2).floor()],
      slots[slots.length - 1],
    ];
  }
}
