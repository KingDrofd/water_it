import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/features/home/data/datasources/open_weather_data_source.dart';
import 'package:water_it/features/home/domain/entities/location_result.dart';

typedef HomeWeatherLoader = Future<void> Function(double lat, double lon);

class HomeLocationController {
  HomeLocationController({
    required HomeWeatherLoader loadWeather,
    required void Function(VoidCallback) setState,
    required void Function(String message) showError,
  })  : _loadWeather = loadWeather,
        _setState = setState,
        _showError = showError;

  final HomeWeatherLoader _loadWeather;
  final void Function(VoidCallback) _setState;
  final void Function(String message) _showError;

  bool isResolvingLocation = false;
  bool didPrompt = false;
  bool hasActiveLocation = false;
  String locationLabel = _unsetLocationLabel;
  String locationNote = _unsetLocationNote;
  final TextEditingController cityController = TextEditingController();

  void dispose() {
    cityController.dispose();
  }

  Future<void> restorePreference(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final choice = prefs.getString(_prefsKeyChoice);
    if (choice == _prefChoiceDevice) {
      await _useDeviceLocation(context, showErrors: false);
    } else if (choice == _prefChoiceCity) {
      final city = prefs.getString(_prefsKeyCity);
      if (city != null && city.trim().isNotEmpty) {
        await _resolveCity(context, city.trim(), showErrors: false);
      }
    } else {
      _setState(() {
        locationLabel = prefs.getString(_prefsKeyLabel) ?? _unsetLocationLabel;
        locationNote = _unsetLocationNote;
      });
    }

    if (!hasActiveLocation) {
      didPrompt = false;
      await promptForLocation(context);
    }
  }

  Future<void> promptForLocation(BuildContext context) async {
    if (isResolvingLocation || didPrompt) {
      return;
    }
    didPrompt = true;
    _LocationChoice? choice;
    try {
      choice = await showModalBottomSheet<_LocationChoice>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose weather location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.my_location),
                    title: const Text('Use device location'),
                    onTap: () =>
                        Navigator.of(context).pop(_LocationChoice.device),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: const Text('Enter a city'),
                    onTap: () =>
                        Navigator.of(context).pop(_LocationChoice.city),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      didPrompt = false;
    }

    if (choice == null) {
      return;
    }

    switch (choice) {
      case _LocationChoice.device:
        await _useDeviceLocation(context, showErrors: true);
      case _LocationChoice.city:
        await _useCityLocation(context);
    }
  }

  Future<void> _useDeviceLocation(
    BuildContext context, {
    required bool showErrors,
  }) async {
    _setState(() {
      isResolvingLocation = true;
    });
    try {
      final permission = await _ensureLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showErrors) {
          _showError('Location permission denied.');
        }
        await _useFallbackLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      final result = await getIt<OpenWeatherDataSource>().reverseGeocode(
        lat: position.latitude,
        lon: position.longitude,
      );

      _setLocationAndLoad(result, _deviceLocationNote);
      await _saveLocationChoice(
        choice: _LocationChoice.device,
        label: result.label,
      );
    } catch (_) {
      if (showErrors) {
        _showError('Unable to get device location.');
      }
      await _useFallbackLocation();
    } finally {
      _setState(() {
        isResolvingLocation = false;
      });
    }
  }

  Future<void> _useCityLocation(BuildContext context) async {
    final city = await _askForCityName(context);
    if (city == null || city.trim().isEmpty) {
      return;
    }
    await _resolveCity(context, city.trim(), showErrors: true);
  }

  Future<void> _resolveCity(
    BuildContext context,
    String city, {
    required bool showErrors,
  }) async {
    _setState(() {
      isResolvingLocation = true;
    });
    try {
      final result = await getIt<OpenWeatherDataSource>().resolveCity(city);
      _setLocationAndLoad(result, _cityLocationNote);
      await _saveLocationChoice(
        choice: _LocationChoice.city,
        city: city,
        label: result.label,
      );
    } catch (_) {
      if (showErrors) {
        _showError('Unable to find that city.');
      }
      await _useFallbackLocation();
    } finally {
      _setState(() {
        isResolvingLocation = false;
      });
    }
  }

  Future<LocationPermission> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<String?> _askForCityName(BuildContext context) {
    cityController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter a city'),
          content: TextField(
            controller: cityController,
            decoration: const InputDecoration(
              hintText: 'City name',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(cityController.text),
              child: const Text('Use city'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _useFallbackLocation() async {
    _setState(() {
      locationLabel = _defaultLocationLabel;
      locationNote = _defaultLocationNote;
      hasActiveLocation = true;
    });
    await _loadWeather(_defaultLat, _defaultLon);
  }

  void _setLocationAndLoad(LocationResult result, String note) {
    _setState(() {
      locationLabel = result.label;
      locationNote = note;
      hasActiveLocation = true;
    });
    _loadWeather(result.lat, result.lon);
  }

  Future<void> _saveLocationChoice({
    required _LocationChoice choice,
    String? city,
    String? label,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyChoice, choice.name);
    if (city == null || city.isEmpty) {
      await prefs.remove(_prefsKeyCity);
    } else {
      await prefs.setString(_prefsKeyCity, city);
    }
    if (label != null && label.isNotEmpty) {
      await prefs.setString(_prefsKeyLabel, label);
    }
  }
}

class LocationPreference {
  final String label;
  final String note;

  const LocationPreference({
    required this.label,
    required this.note,
  });
}

Future<LocationPreference> readLocationPreference() async {
  final prefs = await SharedPreferences.getInstance();
  final choice = prefs.getString(_prefsKeyChoice);
  final label = prefs.getString(_prefsKeyLabel);

  if (choice == _prefChoiceDevice) {
    return LocationPreference(
      label: label ?? _unsetLocationLabel,
      note: _deviceLocationNote,
    );
  }
  if (choice == _prefChoiceCity) {
    return LocationPreference(
      label: label ?? _unsetLocationLabel,
      note: _cityLocationNote,
    );
  }

  return LocationPreference(
    label: label ?? _unsetLocationLabel,
    note: _unsetLocationNote,
  );
}

const double _defaultLat = 37.7749;
const double _defaultLon = -122.4194;
const String _defaultLocationLabel = 'San Francisco, CA';
const String _defaultLocationNote = 'Default location';
const String _unsetLocationLabel = 'Set your location';
const String _unsetLocationNote = 'Tap to choose';
const String _deviceLocationNote = 'Using device location';
const String _cityLocationNote = 'Using saved city';
const String _prefsKeyChoice = 'home_weather_location_choice';
const String _prefsKeyCity = 'home_weather_location_city';
const String _prefsKeyLabel = 'home_weather_location_label';
const String _prefChoiceDevice = 'device';
const String _prefChoiceCity = 'city';

enum _LocationChoice { device, city }
