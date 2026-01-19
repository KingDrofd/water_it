import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/home/presentation/models/home_reminder_item.dart';

class HomeReminderStrip extends StatelessWidget {
  final AppSpacing spacing;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final List<HomeReminderItem> items;
  final ValueChanged<HomeReminderItem>? onTapItem;

  const HomeReminderStrip({
    super.key,
    required this.spacing,
    required this.textTheme,
    required this.colorScheme,
    required this.items,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: EdgeInsets.all(spacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Center(
          child: Text(
            'No reminders yet.',
            style: textTheme.bodySmall,
          ),
        ),
      );
    }

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
                    onTap: onTapItem == null ? null : () => onTapItem!(item),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final HomeReminderItem item;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _ReminderTile({
    required this.item,
    required this.textTheme,
    required this.colorScheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.plantName, style: textTheme.labelLarge),
          const SizedBox(height: 8),
          Icon(item.icon, color: colorScheme.primary, size: 36),
          const SizedBox(height: 8),
          Text(
            item.task,
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEE h:mm a').format(item.dueAt),
            style: textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
