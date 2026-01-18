import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_elements.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/core/widgets/app_bars/custom_app_bar.dart';
import 'package:water_it/core/widgets/nav_bars/custom_nav_bar.dart';
import 'package:water_it/core/widgets/nav_bars/nav_item.dart';

class ThemePreviewPage extends StatefulWidget {
  const ThemePreviewPage({super.key});

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage> {
  int _selectedNavIndex = 0;

  late final List<NavItem> _navItems = const [
    NavItem(label: 'Home', icon: Icon(Icons.home_outlined)),
    NavItem(label: 'Plants', icon: Icon(Icons.local_florist_outlined)),
    NavItem(label: 'Scan', icon: Icon(Icons.camera_alt_outlined)),
    NavItem(label: 'Profile', icon: Icon(Icons.person_outline)),
  ];

  void _setNavIndex(int index) {
    setState(() {
      _selectedNavIndex = index;
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
              child: Column(
                children: [
                  CustomAppBar(
                    elements: AppBarElements(
                      leading: AppBarIconButton(
                        icon: Icons.menu,
                        onTap: () {},
                      ),
                      title: Center(
                        child: Text('Water It', style: textTheme.displaySmall),
                      ),
                      action: AppBarIconButton(
                        icon: Icons.notifications_none,
                        onTap: () {},
                      ),
                    ),
                  ),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: padding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Navigation', style: textTheme.headlineSmall),
                            SizedBox(height: spacing.md),
                            const Spacer(),
                            CustomNavBar(
                              items: _navItems,
                              selectedIndex: _selectedNavIndex,
                              onTap: _setNavIndex,
                            ),
                          ],
                        ),
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
