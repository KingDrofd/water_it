import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/presentation/utils/care_task_visuals.dart';

/// The recent care timeline for one plant.
class CareHistorySection extends StatelessWidget {
  const CareHistorySection({
    super.key,
    required this.events,
    this.taskLabels = const {},
    this.maxEvents = 6,
  });

  final List<CareEvent> events;

  /// Task id -> label, so completed custom tasks show their own name.
  final Map<String, String> taskLabels;
  final int maxEvents;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final visible = events.take(maxEvents).toList();

    if (visible.isEmpty) {
      return Text(
        'No care logged yet.',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: palette.muted),
      );
    }
    return Column(
      children: [
        for (final event in visible)
          CareEventRow(event: event, customLabel: taskLabels[event.taskId]),
      ],
    );
  }
}

class CareEventRow extends StatelessWidget {
  const CareEventRow({super.key, required this.event, this.customLabel});

  final CareEvent event;
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final type = careTaskTypeOf(event.type);
    final note = event.note?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: careTaskTileColor(type, palette),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              careTaskGlyph(type),
              size: 17,
              color: careTaskTint(type, palette),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  careEventTitle(type, customLabel),
                  style: textTheme.bodyMedium,
                ),
                if (note != null && note.isNotEmpty)
                  Text(
                    note,
                    style: textTheme.bodySmall?.copyWith(color: palette.muted),
                  ),
              ],
            ),
          ),
          Text(
            formatCareEventTime(event.completedAt),
            style: textTheme.labelSmall?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

/// Stored event type name back to a task type; unknown names read as custom.
CareTaskType careTaskTypeOf(String name) {
  for (final type in CareTaskType.values) {
    if (type.name == name) {
      return type;
    }
  }
  return CareTaskType.custom;
}

/// Past-tense timeline title: "Watered", "Fertilized", or a custom task's
/// own name.
String careEventTitle(CareTaskType type, [String? customLabel]) {
  switch (type) {
    case CareTaskType.water:
      return 'Watered';
    case CareTaskType.fertilize:
      return 'Fertilized';
    case CareTaskType.mist:
      return 'Misted';
    case CareTaskType.repot:
      return 'Repotted';
    case CareTaskType.prune:
      return 'Pruned';
    case CareTaskType.custom:
      final label = customLabel?.trim();
      return label == null || label.isEmpty ? 'Custom task' : label;
  }
}

/// "Today 9:12 AM", "Yesterday", "3 days ago", or "Mar 4".
String formatCareEventTime(DateTime time, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(time.year, time.month, time.day);
  final dayDiff = today.difference(day).inDays;

  if (dayDiff <= 0) {
    return 'Today ${DateFormat('h:mm a').format(time)}';
  }
  if (dayDiff == 1) {
    return 'Yesterday';
  }
  if (dayDiff < 7) {
    return '$dayDiff days ago';
  }
  return DateFormat('MMM d').format(time);
}
