import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/home/data/datasources/open_weather_data_source.dart';
import 'package:water_it/features/home/domain/entities/location_result.dart';
import 'package:water_it/features/home/presentation/bloc/home_weather_cubit.dart';
import 'package:water_it/features/home/presentation/widgets/home_reminder_strip.dart';
import 'package:water_it/features/home/presentation/widgets/home_weather_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeWeatherCubit>(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  bool _isResolvingLocation = false;
  bool _didPrompt = false;
  bool _hasActiveLocation = false;
  String _locationLabel = _unsetLocationLabel;
  String _locationNote = _unsetLocationNote;
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didPrompt) {
        return;
      }
      _restoreLocationPreference();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _promptForLocation() async {
    if (_isResolvingLocation) {
      return;
    }
    if (_didPrompt) {
      return;
    }
    _didPrompt = true;
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
                    onTap: () => Navigator.of(context)
                        .pop(_LocationChoice.device),
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
      _didPrompt = false;
    }

    if (!mounted || choice == null) {
      return;
    }

    switch (choice) {
      case _LocationChoice.device:
        await _useDeviceLocation(showErrors: true);
      case _LocationChoice.city:
        await _useCityLocation();
    }
  }

  Future<void> _useDeviceLocation({required bool showErrors}) async {
    setState(() {
      _isResolvingLocation = true;
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
    } catch (error) {
      if (showErrors) {
        _showError('Unable to get device location.');
      }
      await _useFallbackLocation();
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<void> _useCityLocation() async {
    final city = await _askForCityName();
    if (city == null || city.trim().isEmpty) {
      return;
    }
    await _resolveCity(city.trim(), showErrors: true);
  }

  Future<void> _resolveCity(
    String city, {
    required bool showErrors,
  }) async {
    setState(() {
      _isResolvingLocation = true;
    });
    try {
      final result = await getIt<OpenWeatherDataSource>().resolveCity(city);
      _setLocationAndLoad(result, _cityLocationNote);
      await _saveLocationChoice(
        choice: _LocationChoice.city,
        city: city,
        label: result.label,
      );
    } catch (error) {
      if (showErrors) {
        _showError('Unable to find that city.');
      }
      await _useFallbackLocation();
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<LocationPermission> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<String?> _askForCityName() {
    _cityController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter a city'),
          content: TextField(
            controller: _cityController,
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
              onPressed: () =>
                  Navigator.of(context).pop(_cityController.text),
              child: const Text('Use city'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _useFallbackLocation() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _locationLabel = _defaultLocationLabel;
      _locationNote = _defaultLocationNote;
      _hasActiveLocation = true;
    });
    await context.read<HomeWeatherCubit>().load(
          lat: _defaultLat,
          lon: _defaultLon,
        );
  }

  void _setLocationAndLoad(LocationResult result, String note) {
    if (!mounted) {
      return;
    }
    setState(() {
      _locationLabel = result.label;
      _locationNote = note;
      _hasActiveLocation = true;
    });
    context.read<HomeWeatherCubit>().load(
          lat: result.lat,
          lon: result.lon,
        );
  }

  Future<void> _restoreLocationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final choice = prefs.getString(_prefsKeyChoice);
    if (!mounted) {
      return;
    }
    if (choice == _prefChoiceDevice) {
      await _useDeviceLocation(showErrors: false);
    } else if (choice == _prefChoiceCity) {
      final city = prefs.getString(_prefsKeyCity);
      if (city != null && city.trim().isNotEmpty) {
        await _resolveCity(city.trim(), showErrors: false);
      }
    } else {
      setState(() {
        _locationLabel =
            prefs.getString(_prefsKeyLabel) ?? _unsetLocationLabel;
        _locationNote = _unsetLocationNote;
      });
    }

    if (!_hasActiveLocation) {
      _didPrompt = false;
      await _promptForLocation();
    }
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

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gutter = AppLayout.gutter(width);

        return ListView(
          padding: EdgeInsets.only(
            left: spacing.lg,
            right: spacing.lg,
            top: AppLayout.navBarInset(
              width,
              spacing: spacing.xxl + spacing.xxl,
            ),
            bottom: AppLayout.navBarInset(width, spacing: spacing.xxl),
          ),
          children: [
            BlocBuilder<HomeWeatherCubit, HomeWeatherState>(
              builder: (context, state) {
                if (state.status == HomeWeatherStatus.loading) {
                  return HomeWeatherSection(
                    slots: buildWeatherPlaceholders(),
                    spacing: spacing,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    gutter: gutter,
                    isPlaceholder: true,
                    title: "Today's Weather",
                    locationLabel: _locationLabel,
                    locationNote: _locationNote,
                    onLocationTap: _promptForLocation,
                  );
                }
                if (state.status == HomeWeatherStatus.failure) {
                  return HomeWeatherSection(
                    slots: const [],
                    spacing: spacing,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    gutter: gutter,
                    errorMessage: state.errorMessage ?? 'Weather unavailable.',
                    title: "Today's Weather",
                    locationLabel: _locationLabel,
                    locationNote: _locationNote,
                    onLocationTap: _promptForLocation,
                  );
                }
                return HomeWeatherSection(
                  slots: state.slots,
                  spacing: spacing,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  gutter: gutter,
                  title: "Today's Weather",
                  locationLabel: _locationLabel,
                  locationNote: _locationNote,
                  onLocationTap: _promptForLocation,
                );
              },
            ),
            SizedBox(height: spacing.lg),
            HomeSectionTitle(title: 'Reminders', textTheme: textTheme),
            SizedBox(height: spacing.sm),
            HomeReminderStrip(
              spacing: spacing,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: spacing.xxl),
          ],
        );
      },
    );
  }
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
