import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/home/presentation/bloc/home_weather_cubit.dart';
import 'package:water_it/features/home/presentation/bloc/home_reminder_cubit.dart';
import 'package:water_it/features/home/presentation/utils/home_location_controller.dart';
import 'package:water_it/features/home/presentation/widgets/home_reminder_strip.dart';
import 'package:water_it/features/home/presentation/widgets/home_weather_section.dart';
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
  late final HomeLocationController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = HomeLocationController(
      loadWeather: _loadWeather,
      setState: (fn) => setState(fn),
      showError: _showError,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationController.restorePreference(context);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
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
                    locationLabel: _locationController.locationLabel,
                    locationNote: _locationController.locationNote,
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
                return HomeReminderStrip(
                  spacing: spacing,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                  items: reminderState.items,
                  onTapItem: (item) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlantDetailPage(plantId: item.plantId),
                      ),
                    );
                  },
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

