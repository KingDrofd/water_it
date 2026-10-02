import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/features/home/presentation/models/home_reminder_item.dart';
import 'package:water_it/features/plants/presentation/utils/care_task_visuals.dart';

/// The Home "Due today" section: a header with the task count and one row
/// per task due today or overdue.
class DueTodayList extends StatelessWidget {
  const DueTodayList({
    super.key,
    required this.items,
    required this.onTapItem,
    required this.onMarkDone,
    required this.onAddPlant,
    this.hasPlants = true,
    this.now,
  });

  final List<HomeReminderItem> items;
  final ValueChanged<HomeReminderItem> onTapItem;
  final ValueChanged<HomeReminderItem> onMarkDone;
  final VoidCallback onAddPlant;

  /// Distinguishes "nothing due" from "no plants at all".
  final bool hasPlants;

  /// Injectable clock for the "due yesterday" wording.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final count = items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Due today', style: textTheme.titleMedium)),
            if (count > 0)
              Text(
                count == 1 ? '1 task' : '$count tasks',
                style: textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _EmptyDue(hasPlants: hasPlants, onAddPlant: onAddPlant)
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DueRow(
                item: item,
                now: now ?? DateTime.now(),
                onTap: () => onTapItem(item),
                onMarkDone: () => onMarkDone(item),
              ),
            ),
      ],
    );
  }
}

class _DueRow extends StatelessWidget {
  const _DueRow({
    required this.item,
    required this.now,
    required this.onTap,
    required this.onMarkDone,
  });

  final HomeReminderItem item;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onMarkDone;

  String _detail(BuildContext context) {
    if (item.isOverdue) {
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(item.dueAt.year, item.dueAt.month, item.dueAt.day);
      final days = DateTime.utc(today.year, today.month, today.day)
          .difference(DateTime.utc(due.year, due.month, due.day))
          .inDays;
      final when = days <= 1 ? 'due yesterday' : 'due $days days ago';
      return '${item.label} · $when';
    }
    return [
      item.label,
      if (item.roomName != null) item.roomName!,
      DateFormat.jm().format(item.dueAt),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final overdue = item.isOverdue;
    final tint = overdue ? palette.overdueInk : careTaskTint(item.type, palette);

    return Material(
      color: overdue ? palette.overdueBg : palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: overdue ? palette.overdueLine : palette.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: overdue
                      ? palette.card.withValues(alpha: 0.6)
                      : careTaskTileColor(item.type, palette),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(careTaskGlyph(item.type), color: tint, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.plantName,
                            style: textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (overdue) ...[
                          const SizedBox(width: 6),
                          _OverdueBadge(palette: palette),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _detail(context),
                      style: textTheme.bodySmall?.copyWith(
                        color: overdue ? palette.overdueInk : palette.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CheckButton(
                overdue: overdue,
                onTap: onMarkDone,
                label: 'Mark ${item.label} done for ${item.plantName}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: palette.overdueInk,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'OVERDUE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.overdueBg,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({
    required this.overdue,
    required this.onTap,
    required this.label,
  });

  final bool overdue;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: overdue ? palette.overdueInk : Colors.transparent,
            border: overdue
                ? null
                : Border.all(color: palette.primary, width: 2),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 20,
            color: overdue ? palette.overdueBg : palette.deep,
          ),
        ),
      ),
    );
  }
}

class _EmptyDue extends StatelessWidget {
  const _EmptyDue({required this.hasPlants, required this.onAddPlant});

  final bool hasPlants;
  final VoidCallback onAddPlant;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        children: [
          Icon(
            hasPlants ? Icons.eco_rounded : Icons.local_florist_rounded,
            color: palette.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasPlants
                  ? 'Nothing due today. Your plants are happy.'
                  : 'No plants yet.',
              style: textTheme.bodyMedium,
            ),
          ),
          if (!hasPlants)
            TextButton(onPressed: onAddPlant, child: const Text('Add one')),
        ],
      ),
    );
  }
}
