import 'dart:convert';
import 'dart:io';

import 'package:water_it/features/home/domain/entities/location_result.dart';
import 'package:water_it/features/home/data/models/weather_slot_model.dart';

class OpenWeatherDataSource {
  OpenWeatherDataSource({
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient();

  static const String _baseUrl = 'api.openweathermap.org';
  static const String _apiKey =
      String.fromEnvironment('OPENWEATHER_API_KEY');

  final HttpClient _httpClient;

  Future<List<WeatherSlotModel>> fetchForecast({
    required double lat,
    required double lon,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError('OpenWeather API key is missing.');
    }

    final uri = Uri.https(_baseUrl, '/data/2.5/forecast', {
      'lat': lat.toStringAsFixed(4),
      'lon': lon.toStringAsFixed(4),
      'units': 'metric',
      'appid': _apiKey,
    });

    final request = await _httpClient.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('OpenWeather error: ${response.statusCode}');
    }

    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final items = decoded['list'] as List<dynamic>? ?? const [];

    return items
        .map((item) => WeatherSlotModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<LocationResult> resolveCity(String city) async {
    if (_apiKey.isEmpty) {
      throw StateError('OpenWeather API key is missing.');
    }

    final uri = Uri.https(_baseUrl, '/geo/1.0/direct', {
      'q': city,
      'limit': '1',
      'appid': _apiKey,
    });

    final request = await _httpClient.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('OpenWeather error: ${response.statusCode}');
    }

    final body = await response.transform(utf8.decoder).join();
    final items = jsonDecode(body) as List<dynamic>;
    if (items.isEmpty) {
      throw StateError('No location found for "$city".');
    }

    return _parseLocation(items.first as Map<String, dynamic>);
  }

  Future<LocationResult> reverseGeocode({
    required double lat,
    required double lon,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError('OpenWeather API key is missing.');
    }

    final uri = Uri.https(_baseUrl, '/geo/1.0/reverse', {
      'lat': lat.toStringAsFixed(4),
      'lon': lon.toStringAsFixed(4),
      'limit': '1',
      'appid': _apiKey,
    });

    final request = await _httpClient.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('OpenWeather error: ${response.statusCode}');
    }

    final body = await response.transform(utf8.decoder).join();
    final items = jsonDecode(body) as List<dynamic>;
    if (items.isEmpty) {
      throw StateError('No location found for coordinates.');
    }

    return _parseLocation(items.first as Map<String, dynamic>);
  }

  LocationResult _parseLocation(Map<String, dynamic> data) {
    final lat = (data['lat'] as num).toDouble();
    final lon = (data['lon'] as num).toDouble();
    final name = data['name'] as String? ?? 'Unknown';
    final state = data['state'] as String?;
    final country = data['country'] as String?;

    return LocationResult(
      lat: lat,
      lon: lon,
      label: _buildLabel(name, state, country),
    );
  }

  String _buildLabel(String name, String? state, String? country) {
    final pieces = <String>[name];
    if (state != null && state.isNotEmpty) {
      pieces.add(state);
    }
    if (country != null && country.isNotEmpty) {
      pieces.add(country);
    }
    return pieces.join(', ');
  }
}
