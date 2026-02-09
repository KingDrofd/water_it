import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_elements.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/core/widgets/app_bars/custom_app_bar.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/nav_bars/custom_nav_bar.dart';
import 'package:water_it/core/widgets/nav_bars/nav_item.dart';
import 'package:water_it/features/settings/presentation/pages/settings_page.dart';
import 'package:water_it/features/app_shell/presentation/widgets/quick_actions_drawer.dart';
import 'package:water_it/features/home/presentation/pages/home_page.dart';
import 'package:water_it/features/plants/presentation/pages/plants_page.dart';
import 'package:water_it/features/plants/presentation/pages/plant_form_page.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/scan/presentation/pages/scan_page.dart';
import 'package:water_it/features/home/presentation/utils/home_location_controller.dart';
import 'package:water_it/features/feedback/presentation/pages/feedback_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _selectedIndex = 0;
  bool _showBars = true;
  final PageController _pageController = PageController();

  final List<Widget> _pages = const [
    HomePage(),
    PlantsPage(),
    ScanPage(),
  ];

  late final List<NavItem> _navItems = const [
    NavItem(label: 'Home', icon: Icon(Icons.home_outlined)),
    NavItem(label: 'Plants', icon: Icon(Icons.local_florist_outlined)),
    NavItem(label: 'Add Plant', icon: Icon(Icons.camera_alt_outlined)),
  ];

  final List<String> _titles = const [
    'Home',
    'Plants',
    'Add Plant',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
      _requestWeatherLocation();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return Scaffold(
      drawer: QuickActionsDrawer(
        onActionSelected: _handleQuickAction,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = AppLayout.pagePadding(width);
          final contentMax = AppLayout.maxContentWidth(width);
          final scale = AppLayout.scaleForWidth(width);
          final gutter = AppLayout.gutter(width);
          final mediaPadding = MediaQuery.of(context).padding.top;
          final appBarHeight = mediaPadding + (spacing.sm * scale) + (72 * scale);
          final navBarHeight = (72 * scale) + (gutter * 2);

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
                        top: _showBars ? appBarHeight : spacing.lg,
                        bottom: _showBars ? navBarHeight : spacing.xxl,
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
                    top: _showBars ? 0 : -appBarHeight,
                    left: 0,
                    right: 0,
                    child: Builder(
                      builder: (appBarContext) {
                        return CustomAppBar(
                          elements: AppBarElements(
                            leading: AppBarIconButton(
                              icon: Icons.menu,
                              onTap: () =>
                                  Scaffold.of(appBarContext).openDrawer(),
                            ),
                            title: Center(
                              child: Text(
                                _titles[_selectedIndex],
                                style:
                                    Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                            action: AppBarIconButton(
                              icon: _selectedIndex == 1
                                  ? Icons.add
                                  : Icons.notifications_none,
                              onTap: () {
                                if (_selectedIndex == 1) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PlantFormPage(),
                                    ),
                                  ).then((_) {
                                    context
                                        .read<PlantListCubit>()
                                        .loadPlants();
                                  });
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: 0,
                    right: 0,
                    bottom: _showBars ? 0 : -navBarHeight,
                    child: CustomNavBar(
                      items: _navItems,
                      selectedIndex: _selectedIndex,
                      onTap: _setIndex,
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

  void _handleQuickAction(QuickAction action) {
    Navigator.of(context).maybePop();
    if (!mounted) {
      return;
    }

    switch (action) {
      case QuickAction.about:
        _openAbout();
        return;
      case QuickAction.settings:
        _openSettings();
        return;
      case QuickAction.feedback:
        _openFeedback();
        return;
    }
  }

  void _openAbout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SettingsPage(
            initialSection: SettingsSection.about,
          ),
        ),
      );
    });
  }

  void _openSettings() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SettingsPage(),
        ),
      );
    });
  }

  void _openFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FeedbackPage(),
        ),
      );
    });
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
    }
  }

  Future<void> _requestWeatherLocation() async {
    if (!mounted) {
      return;
    }
    final controller = HomeLocationController(
      loadWeather: (_, __) async {},
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
      loadWeather: (_, __) async {},
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
