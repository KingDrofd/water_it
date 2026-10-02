import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/notifications/reminder_delivery_banner.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/add_plant/presentation/add_plant_sheet.dart';
import 'package:water_it/features/home/presentation/bloc/home_reminder_cubit.dart';
import 'package:water_it/features/home/presentation/bloc/home_weather_cubit.dart';
import 'package:water_it/features/home/presentation/utils/home_location_controller.dart';
import 'package:water_it/features/home/presentation/widgets/due_today_list.dart';
import 'package:water_it/features/home/presentation/widgets/home_weather_section.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/pages/plant_detail_page.dart';
import 'package:water_it/features/settings/presentation/pages/settings_page.dart';

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
    AppSettings.syncDisplayName();
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

  Future<void> _addPlant() async {
    await showAddPlantSheet(context);
    await getIt<PlantListCubit>().loadPlants();
  }

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = AppLayout.gutter(constraints.maxWidth);

        return ListView(
          // Horizontal padding comes from the shell.
          padding: EdgeInsets.only(top: spacing.md, bottom: spacing.xl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Water It',
                    style: textTheme.displayMedium?.copyWith(
                      color: palette.primary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: Icon(Icons.settings_rounded, color: palette.muted),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            ValueListenableBuilder<String?>(
              valueListenable: AppSettings.displayNameNotifier,
              builder: (context, name, _) => Text(
                greetingFor(DateTime.now(), name),
                style: textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            SizedBox(height: spacing.lg),
            const ReminderDeliveryBanner(),
            BlocBuilder<HomeReminderCubit, HomeReminderState>(
              builder: (context, state) {
                final hasPlants =
                    context.watch<PlantListCubit>().state.plants.isNotEmpty;
                return DueTodayList(
                  items: state.items,
                  hasPlants: hasPlants,
                  onAddPlant: _addPlant,
                  onMarkDone: (item) async {
                    await context.read<HomeReminderCubit>().markDone(item);
                    // Keeps library badges and the schedule in step.
                    await getIt<PlantListCubit>().loadPlants();
                  },
                  onTapItem: (item) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlantDetailPage(plantId: item.plantId),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: spacing.md),
            BlocBuilder<HomeWeatherCubit, HomeWeatherState>(
              builder: (context, state) {
                return HomeWeatherSection(
                  slots: state.status == HomeWeatherStatus.loading
                      ? buildWeatherPlaceholders()
                      : state.status == HomeWeatherStatus.failure
                          ? const []
                          : state.slots,
                  spacing: spacing,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  gutter: gutter,
                  isPlaceholder: state.status == HomeWeatherStatus.loading,
                  errorMessage: state.status == HomeWeatherStatus.failure
                      ? state.errorMessage ?? 'Weather unavailable.'
                      : null,
                  onRetry: state.status == HomeWeatherStatus.failure
                      ? () => _locationController.restorePreference(context)
                      : null,
                  locationLabel: _locationController.locationLabel,
                  locationNote: _locationController.locationNote,
                  temperatureUnit: _temperatureUnit,
                  onLocationTap: () =>
                      _locationController.promptForLocation(context),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// "Good morning, Sam", or just "Good morning" when no name is set.
String greetingFor(DateTime now, String? name) {
  final part = now.hour < 12
      ? 'Good morning'
      : now.hour < 18
          ? 'Good afternoon'
          : 'Good evening';
  final trimmed = name?.trim();
  return trimmed == null || trimmed.isEmpty ? part : '$part, $trimmed';
}
