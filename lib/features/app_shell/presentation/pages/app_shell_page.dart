import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_elements.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/core/widgets/app_bars/custom_app_bar.dart';
import 'package:water_it/core/widgets/nav_bars/custom_nav_bar.dart';
import 'package:water_it/core/widgets/nav_bars/nav_item.dart';
import 'package:water_it/features/home/presentation/pages/home_page.dart';
import 'package:water_it/features/plants/presentation/pages/plants_page.dart';
import 'package:water_it/features/plants/presentation/pages/plant_form_page.dart';
import 'package:water_it/features/profile/presentation/pages/profile_page.dart';
import 'package:water_it/features/scan/presentation/pages/scan_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = AppLayout.pagePadding(width);
          final contentMax = AppLayout.maxContentWidth(width);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: padding.left,
                        right: padding.right,
                      ),
                      child: _pages[_selectedIndex],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CustomAppBar(
                      elements: AppBarElements(
                        leading: AppBarIconButton(
                          icon: Icons.menu,
                          onTap: () {},
                        ),
                        title: Center(
                          child: Text(
                            _titles[_selectedIndex],
                            style: textTheme.displaySmall,
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
                            );
                          }
                        },
                      ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: spacing.lg),
                      child: CustomNavBar(
                        items: _navItems,
                        selectedIndex: _selectedIndex,
                        onTap: _setIndex,
                      ),
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
}
