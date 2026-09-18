import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';
import 'package:water_it/features/plants/domain/entities/care_event.dart';

/// "Mark watered" action plus the recent care timeline for one plant.
class CareHistorySection extends StatelessWidget {
  const CareHistorySection({
    super.key,
    required this.events,
    required this.isLogging,
    required this.onMarkWatered,
    this.maxEvents = 6,
  });

  final List<CareEvent> events;
  final bool isLogging;
  final VoidCallback onMarkWatered;
  final int maxEvents;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visible = events.take(maxEvents).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPrimaryButton(
          onPressed: isLogging ? null : onMarkWatered,
          icon: const Icon(Icons.water_drop),
          label: isLogging ? 'Saving...' : 'Mark watered',
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Text('No care logged yet.', style: textTheme.bodySmall)
        else
          ...visible.map((event) => CareEventRow(event: event)),
      ],
    );
  }
}

class CareEventRow extends StatelessWidget {
  const CareEventRow({super.key, required this.event});

  final CareEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final note = event.note?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.water_drop, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Watered', style: textTheme.labelLarge),
                if (note != null && note.isNotEmpty)
                  Text(note, style: textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            formatCareEventTime(event.completedAt),
            style: textTheme.labelSmall,
          ),
        ],
      ),
    );
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
