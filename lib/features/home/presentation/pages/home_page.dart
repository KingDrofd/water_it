import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/home/presentation/bloc/home_weather_cubit.dart';
import 'package:water_it/features/home/presentation/bloc/home_reminder_cubit.dart';
import 'package:water_it/features/home/presentation/utils/home_location_controller.dart';
import 'package:water_it/features/home/presentation/widgets/home_reminder_strip.dart';
import 'package:water_it/features/home/presentation/widgets/home_weather_section.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/pages/plant_form_page.dart';
import 'package:water_it/features/plants/presentation/pages/plant_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<HomeWeatherCubit>(),
        ),
        BlocProvider(
          create: (_) => getIt<HomeReminderCubit>()..loadNextReminders(),
        ),
      ],
      child: BlocListener<PlantListCubit, PlantListState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.plants.length != current.plants.length,
        listener: (context, state) {
          context.read<HomeReminderCubit>().loadNextReminders();
        },
        child: const _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late final HomeLocationController _locationController;
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;

  @override
  void initState() {
    super.initState();
    AppSettings.temperatureUnitNotifier.addListener(_handleTemperatureChange);
    AppSettings.syncTemperatureUnit();
    _locationController = HomeLocationController(
      loadWeather: _loadWeather,
      setState: (fn) => setState(fn),
      showError: _showError,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationController.restorePreference(context, promptIfUnset: false);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    AppSettings.temperatureUnitNotifier
        .removeListener(_handleTemperatureChange);
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadWeather(double lat, double lon) {
    return context.read<HomeWeatherCubit>().load(lat: lat, lon: lon);
  }

  void _handleTemperatureChange() {
    if (!mounted) {
      return;
    }
    setState(() {
      _temperatureUnit = AppSettings.temperatureUnitNotifier.value;
    });
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
            top: spacing.lg,
            bottom: spacing.xxl,
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
                    locationLabel: _locationController.locationLabel,
                    locationNote: _locationController.locationNote,
                    temperatureUnit: _temperatureUnit,
                    onLocationTap: () =>
                        _locationController.promptForLocation(context),
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
                    locationLabel: _locationController.locationLabel,
                    locationNote: _locationController.locationNote,
                    temperatureUnit: _temperatureUnit,
                    onRetry: () {
                      _locationController.restorePreference(context);
                    },
                    onLocationTap: () =>
                        _locationController.promptForLocation(context),
                  );
                }
                return HomeWeatherSection(
                  slots: state.slots,
                  spacing: spacing,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  gutter: gutter,
                  title: "Today's Weather",
                  locationLabel: _locationController.locationLabel,
                  locationNote: _locationController.locationNote,
                  temperatureUnit: _temperatureUnit,
                  onLocationTap: () =>
                      _locationController.promptForLocation(context),
                );
              },
            ),
            SizedBox(height: spacing.lg),
            HomeSectionTitle(title: 'Reminders', textTheme: textTheme),
            SizedBox(height: spacing.sm),
            BlocBuilder<HomeReminderCubit, HomeReminderState>(
              builder: (context, reminderState) {
                final nextReminder = reminderState.items.isEmpty
                    ? null
                    : reminderState.items.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nextReminder != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Next: ${DateFormat('EEE h:mm a').format(nextReminder.dueAt)}'
                          ' - ${nextReminder.plantName}',
                          style: textTheme.bodySmall,
                        ),
                      ),
                    HomeReminderStrip(
                      spacing: spacing,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                      items: reminderState.items,
                      onEmptyAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PlantFormPage(),
                          ),
                        );
                      },
                      emptyActionLabel: 'Add a plant',
                      onTapItem: (item) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PlantDetailPage(plantId: item.plantId),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: spacing.xxl),
          ],
        );
      },
    );
  }
}

