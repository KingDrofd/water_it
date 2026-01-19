import 'package:water_it/features/home/domain/entities/weather_slot.dart';

class WeatherSlotModel extends WeatherSlot {
  const WeatherSlotModel({
    required super.time,
    required super.temperatureC,
    required super.conditionKey,
    required super.cloudiness,
  });

  factory WeatherSlotModel.fromMap(Map<String, dynamic> map) {
    final timestamp = map['dt'] as int;
    final main = map['main'] as Map<String, dynamic>;
    final clouds = map['clouds'] as Map<String, dynamic>? ?? const {};
    final cloudiness = (clouds['all'] as num?)?.toInt() ?? 0;
    final weatherList = map['weather'] as List<dynamic>? ?? const [];
    final weatherMain = weatherList.isNotEmpty
        ? (weatherList.first as Map<String, dynamic>)['main'] as String?
        : null;

    return WeatherSlotModel(
      time: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
          .toLocal(),
      temperatureC: (main['temp'] as num).toDouble(),
      conditionKey: _mapConditionKey(weatherMain),
      cloudiness: cloudiness,
    );
  }

  static String _mapConditionKey(String? main) {
    switch (main) {
      case 'Clear':
        return 'sunny';
      case 'Clouds':
        return 'cloudy';
      case 'Rain':
      case 'Drizzle':
        return 'rainy';
      case 'Thunderstorm':
        return 'storm';
      case 'Snow':
        return 'snow';
      case 'Mist':
      case 'Fog':
      case 'Haze':
        return 'mist';
      default:
        return 'cloudy';
    }
  }
}
