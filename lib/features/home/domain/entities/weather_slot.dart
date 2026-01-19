class WeatherSlot {
  const WeatherSlot({
    required this.time,
    required this.temperatureC,
    required this.conditionKey,
    required this.cloudiness,
  });

  final DateTime time;
  final double temperatureC;
  final String conditionKey;
  final int cloudiness;
}
