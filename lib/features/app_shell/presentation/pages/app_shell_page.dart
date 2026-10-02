import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/notifications/reminder_permission_flow.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/features/add_plant/presentation/add_plant_sheet.dart';
import 'package:water_it/features/app_shell/presentation/widgets/app_bottom_nav.dart';
import 'package:water_it/features/home/presentation/pages/home_page.dart';
import 'package:water_it/features/plants/presentation/pages/plants_page.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/home/presentation/utils/home_location_controller.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _showBars = true;
  final PageController _pageController = PageController();

  final List<Widget> _pages = const [
    HomePage(),
    PlantsPage(),
  ];

  static const List<AppNavDestination> _destinations = [
    AppNavDestination(label: 'Home', icon: Icons.home_rounded),
    AppNavDestination(label: 'Plants', icon: Icons.local_florist_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
      _requestWeatherLocation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user may have just granted "Alarms & reminders" in system
      // settings; pick that up and rebuild the schedule.
      ReminderPermissionFlow.refreshAfterResume();
    }
  }

  void _setIndex(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handleScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return;
    }
    final direction = notification.direction;
    if (direction == ScrollDirection.reverse && _showBars) {
      setState(() {
        _showBars = false;
      });
    } else if (direction == ScrollDirection.forward && !_showBars) {
      setState(() {
        _showBars = true;
      });
    }
  }

  Future<void> _addPlant() async {
    await showAddPlantSheet(context);
    if (mounted) {
      await context.read<PlantListCubit>().loadPlants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = AppLayout.pagePadding(width);
          final contentMax = AppLayout.maxContentWidth(width);
          final media = MediaQuery.of(context).padding;
          const navHeight = 68.0;
          final navInset = navHeight + 16 + media.bottom;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(
                        left: padding.left,
                        right: padding.right,
                        top: media.top,
                        bottom: _showBars ? navInset : media.bottom,
                      ),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is UserScrollNotification) {
                            _handleScroll(notification);
                          }
                          return false;
                        },
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          children: _pages,
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: 16,
                    right: 16,
                    bottom: _showBars ? 12 + media.bottom : -navInset,
                    child: AppBottomNav(
                      destinations: _destinations,
                      selectedIndex: _selectedIndex,
                      onSelect: _setIndex,
                      onAddPlant: _addPlant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final enabled = await AppSettings.getWateringRemindersEnabled();
    if (!enabled || !mounted) {
      return;
    }
    final prompted = await AppSettings.getNotificationPrompted();
    if (prompted || !mounted) {
      return;
    }
    final allow = await _showNotificationPrompt(
      title: 'Enable reminders?',
      message:
          'Water It can remind you to water plants at your chosen times.',
      allowLabel: 'Allow',
    );
    await AppSettings.setNotificationPrompted(true);
    if (!allow || !mounted) {
      await AppSettings.setWateringRemindersEnabled(false);
      return;
    }
    final service = getIt<NotificationService>();
    final granted = await service.requestPermissions();
    if (!granted) {
      await AppSettings.setWateringRemindersEnabled(false);
      return;
    }
    // Notifications alone only get them delivered - precise timing is a
    // second, separate Android grant.
    if (!mounted) {
      return;
    }
    await ReminderPermissionFlow.requestExactAlarms(context);
  }

  Future<void> _requestWeatherLocation() async {
    if (!mounted) {
      return;
    }
    final controller = HomeLocationController(
      loadWeather: (_, _) async {},
      setState: (_) {},
      showError: (_) {},
    );
    await controller.restorePreference(context, promptIfUnset: false);
    final shouldPrompt = !controller.hasActiveLocation && !controller.didPrompt;
    controller.dispose();
    if (!shouldPrompt || !mounted) {
      return;
    }
    final prompted = await AppSettings.getWeatherPrompted();
    if (prompted || !mounted) {
      return;
    }

    final allow = await _showNotificationPrompt(
      title: 'Show local weather?',
      message:
          'Water It can also show local weather to help plan plant care.',
      allowLabel: 'Choose',
    );
    await AppSettings.setWeatherPrompted(true);
    if (!allow || !mounted) {
      return;
    }
    final promptController = HomeLocationController(
      loadWeather: (_, _) async {},
      setState: (_) {},
      showError: (_) {},
    );
    await promptController.promptForLocation(context);
    promptController.dispose();
  }

  Future<bool> _showNotificationPrompt({
    required String title,
    required String message,
    required String allowLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not now'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(allowLabel),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
