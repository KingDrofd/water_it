import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_spacing.dart';

class HomeReminderStrip extends StatelessWidget {
  final AppSpacing spacing;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const HomeReminderStrip({
    super.key,
    required this.spacing,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _ReminderItem(label: 'Plant 1', task: 'Pruning', icon: Icons.spa),
      _ReminderItem(label: 'Plant 2', task: 'Watering', icon: Icons.water_drop),
      _ReminderItem(
        label: 'Plant 3',
        task: 'Watering and Pruning',
        icon: Icons.local_florist,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                  child: _ReminderTile(
                    item: item,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReminderItem {
  final String label;
  final String task;
  final IconData icon;

  const _ReminderItem({
    required this.label,
    required this.task,
    required this.icon,
  });
}

class _ReminderTile extends StatelessWidget {
  final _ReminderItem item;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _ReminderTile({
    required this.item,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.label, style: textTheme.labelLarge),
        const SizedBox(height: 8),
        Icon(item.icon, color: colorScheme.primary, size: 36),
        const SizedBox(height: 8),
        Text(
          item.task,
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
