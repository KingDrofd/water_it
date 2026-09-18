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
  final ValueChanged<HomeReminderItem>? onMarkDone;
  final VoidCallback? onEmptyAction;
  final String? emptyActionLabel;

  const HomeReminderStrip({
    super.key,
    required this.spacing,
    required this.textTheme,
    required this.colorScheme,
    required this.items,
    this.onTapItem,
    this.onMarkDone,
    this.onEmptyAction,
    this.emptyActionLabel,
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
        child: Column(
          children: [
            Text(
              'No reminders yet.',
              style: textTheme.bodySmall,
            ),
            if (onEmptyAction != null && emptyActionLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onEmptyAction,
                child: Text(emptyActionLabel!),
              ),
            ],
          ],
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
                    onMarkDone:
                        onMarkDone == null ? null : () => onMarkDone!(item),
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
  final VoidCallback? onMarkDone;

  const _ReminderTile({
    required this.item,
    required this.textTheme,
    required this.colorScheme,
    this.onTap,
    this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final accent = item.isOverdue ? colorScheme.error : colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.plantName, style: textTheme.labelLarge),
          const SizedBox(height: 8),
          Icon(item.icon, color: accent, size: 36),
          const SizedBox(height: 8),
          Text(
            item.task,
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            item.isOverdue
                ? 'Overdue - ${DateFormat('EEE').format(item.dueAt)}'
                : DateFormat('EEE h:mm a').format(item.dueAt),
            style: textTheme.labelSmall?.copyWith(
              color: item.isOverdue ? colorScheme.error : null,
            ),
          ),
          if (onMarkDone != null) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onMarkDone,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 18, color: accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
