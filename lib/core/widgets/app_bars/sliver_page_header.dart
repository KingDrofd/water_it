import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';

class SliverPageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final double height;

  const SliverPageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverPageHeaderDelegate(
        height: height,
        title: title,
        onBack: onBack,
      ),
    );
  }
}

class _SliverPageHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final String title;
  final VoidCallback onBack;

  _SliverPageHeaderDelegate({
    required this.height,
    required this.title,
    required this.onBack,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return Container(
      color: colorScheme.background,
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppBarIconButton(
              icon: Icons.chevron_left,
              onTap: onBack,
              size: 48,
              radius: 12,
              iconSize: 30,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              style: textTheme.displaySmall?.copyWith(fontSize: 26),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SliverPageHeaderDelegate oldDelegate) {
    return oldDelegate.title != title || oldDelegate.height != height;
  }
}
