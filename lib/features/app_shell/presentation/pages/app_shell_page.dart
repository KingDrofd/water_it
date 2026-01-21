import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_elements.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/core/widgets/app_bars/custom_app_bar.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/nav_bars/custom_nav_bar.dart';
import 'package:water_it/core/widgets/nav_bars/nav_item.dart';
import 'package:water_it/features/app_shell/presentation/pages/quick_action_info_page.dart';
import 'package:water_it/features/settings/presentation/pages/settings_page.dart';
import 'package:water_it/features/app_shell/presentation/widgets/quick_actions_drawer.dart';
import 'package:water_it/features/home/presentation/pages/home_page.dart';
import 'package:water_it/features/plants/presentation/pages/plants_page.dart';
import 'package:water_it/features/plants/presentation/pages/plant_form_page.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/profile/presentation/pages/profile_page.dart';
import 'package:water_it/features/scan/presentation/pages/scan_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _selectedIndex = 0;
  bool _showBars = true;

  late final List<Widget> _pages = const [
    HomePage(),
    PlantsPage(),
    ScanPage(),
    ProfilePage(),
  ];

  late final List<NavItem> _navItems = const [
    NavItem(label: 'Home', icon: Icon(Icons.home_outlined)),
    NavItem(label: 'Plants', icon: Icon(Icons.local_florist_outlined)),
    NavItem(label: 'Scan', icon: Icon(Icons.camera_alt_outlined)),
    NavItem(label: 'Profile', icon: Icon(Icons.person_outline)),
  ];

  final List<String> _titles = const [
    'Home',
    'Plants',
    'Scan',
    'Profile',
  ];

  void _setIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleScroll(UserScrollNotification notification) {
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
                        child: IndexedStack(
                          index: _selectedIndex,
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
      case QuickAction.myPlants:
        _setIndex(1);
        return;
      case QuickAction.settings:
        _openSettings();
        return;
      case QuickAction.backupRestore:
        _openQuickActionInfo(
          title: 'Backup & Restore',
          description:
              'Save your plant data and bring it back on a new device.',
          icon: Icons.backup,
        );
        return;
      case QuickAction.about:
        _openQuickActionInfo(
          title: 'About',
          description:
              'Learn more about Water It and the ideas behind the app.',
          icon: Icons.info_outline,
        );
        return;
      case QuickAction.feedback:
        _openQuickActionInfo(
          title: 'Feedback',
          description:
              'Share bugs, ideas, or feature requests so we can keep improving.',
          icon: Icons.feedback_outlined,
        );
        return;
    }
  }

  void _openQuickActionInfo({
    required String title,
    required String description,
    required IconData icon,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuickActionInfoPage(
            title: title,
            description: description,
            icon: icon,
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
}
