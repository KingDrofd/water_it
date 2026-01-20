import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_elements.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/core/widgets/app_bars/custom_app_bar.dart';

class QuickActionInfoPage extends StatelessWidget {
  const QuickActionInfoPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

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
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      title: Center(
                        child: Text(
                          title,
                          style: textTheme.displaySmall,
                        ),
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
                            Row(
                              children: [
                                Icon(icon, size: 28),
                                SizedBox(width: spacing.sm),
                                Text(
                                  title,
                                  style: textTheme.headlineSmall,
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.sm),
                            Text(
                              description,
                              style: textTheme.bodyLarge,
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
