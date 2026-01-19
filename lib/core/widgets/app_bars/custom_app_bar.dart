import 'package:flutter/material.dart';

import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_elements.dart';

class CustomAppBar extends StatelessWidget {
  final AppBarElements elements;

  const CustomAppBar({
    super.key,
    required this.elements,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = AppLayout.scaleForWidth(width);
        final radius = 15 * scale;
        final paddingTop = spacing.sm * scale;
        final gutter = AppLayout.gutter(width);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: paddingTop,
              right: gutter,
              left: gutter,
            ),
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.md * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (elements.leading != null)
                      Padding(
                        padding: EdgeInsets.only(right: spacing.sm * scale),
                        child: elements.leading!,
                      ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: elements.title,
                      ),
                    ),
                    if (elements.action != null) ...[
                      SizedBox(width: spacing.sm * scale),
                      elements.action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
