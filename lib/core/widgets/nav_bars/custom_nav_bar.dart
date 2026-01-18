import 'package:flutter/material.dart';

import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/nav_bars/nav_item.dart';

class CustomNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = AppLayout.scaleForWidth(width);
        final radius = 15 * scale;
        final gutter = AppLayout.gutter(width);

        return Padding(
          padding: EdgeInsets.all(gutter),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(57, 0, 0, 0),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            height: 72 * scale,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == selectedIndex;
                final indicatorWidth = isSelected ? 48 * scale : 0.0;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.sm * scale),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashFactory: NoSplash.splashFactory,
                        borderRadius: BorderRadius.circular(radius),
                        onTap: () => onTap(index),
                        child: SizedBox(
                          height: 48 * scale,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    width: indicatorWidth,
                                    height: 24 * scale,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(radius),
                                    ),
                                  ),
                                  IconTheme(
                                    data: IconThemeData(
                                      color: colorScheme.onSurface,
                                    ),
                                    child: item.icon,
                                  ),
                                ],
                              ),
                              Text(
                                item.label,
                                style: textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
