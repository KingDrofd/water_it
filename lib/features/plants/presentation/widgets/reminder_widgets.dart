import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/presentation/utils/plant_form_handlers.dart';

class ReminderDraft {
  ReminderDraft({
    required this.id,
    required this.notesController,
    this.preferredTime,
    Set<int>? weekdays,
  }) : weekdays = weekdays ?? <int>{};

  factory ReminderDraft.empty() {
    return ReminderDraft(
      id: const Uuid().v4(),
      notesController: TextEditingController(),
      weekdays: <int>{},
    );
  }

  factory ReminderDraft.fromReminder(WateringReminder reminder) {
    return ReminderDraft(
      id: reminder.id,
      notesController: TextEditingController(text: reminder.notes ?? ''),
      preferredTime: reminder.preferredTime,
      weekdays: reminder.weekdays.toSet(),
    );
  }

  final String id;
  final TextEditingController notesController;
  DateTime? preferredTime;
  final Set<int> weekdays;

  void dispose() {
    notesController.dispose();
  }
}

class ReminderInputRow extends StatelessWidget {
  final ReminderDraft reminder;
  final VoidCallback? onRemove;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;
  final ValueChanged<int> onToggleDay;

  const ReminderInputRow({
    super.key,
    required this.reminder,
    this.onRemove,
    required this.onPickTime,
    required this.onClearTime,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelLarge?.copyWith(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WeekdayPicker(
          selectedDays: reminder.weekdays,
          onToggle: onToggleDay,
          onRemove: onRemove,
        ),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                reminder.preferredTime == null
                    ? 'Set reminder time'
                    : DateFormat('h:mm a').format(reminder.preferredTime!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: onPickTime,
              child: const Text('Pick'),
            ),
            if (reminder.preferredTime != null)
              TextButton(
                onPressed: onClearTime,
                child: const Text('Clear'),
              ),
          ],
        ),
        SizedBox(height: spacing.sm),
        TextField(
          controller: reminder.notesController,
          decoration: InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Water sparingly in winter',
            labelStyle: labelStyle,
          ),
        ),
      ],
    );
  }
}

class ReminderInputList extends StatelessWidget {
  final List<ReminderDraft> reminders;
  final ReminderHandlers handlers;
  final VoidCallback onChanged;

  const ReminderInputList({
    super.key,
    required this.reminders,
    required this.handlers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Text(
        'No reminders yet.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return Column(
      children: reminders
          .map(
            (reminder) => Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: ReminderInputRow(
                reminder: reminder,
                onPickTime: () => handlers.pickTime(
                  context: context,
                  reminder: reminder,
                  onChanged: onChanged,
                ),
                onClearTime: () => handlers.clearTime(
                  reminder: reminder,
                  onChanged: onChanged,
                ),
                onToggleDay: (day) => handlers.toggleDay(
                  reminder: reminder,
                  day: day,
                  onChanged: onChanged,
                ),
                onRemove: reminders.length > 1
                    ? () => handlers.removeReminder(
                          reminders: reminders,
                          reminder: reminder,
                          onChanged: onChanged,
                        )
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }
}

class WeekdayPicker extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;
  final VoidCallback? onRemove;

  const WeekdayPicker({
    super.key,
    required this.selectedDays,
    required this.onToggle,
    this.onRemove,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: spacing.xs,
            children: List.generate(_labels.length, (index) {
              final day = index + 1;
              final selected = selectedDays.contains(day);
              return ChoiceChip(
                label: Text(_labels[index]),
                selected: selected,
                onSelected: (_) => onToggle(day),
              );
            }),
          ),
        ),
        if (onRemove != null) ...[
          SizedBox(width: spacing.sm),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
            tooltip: 'Remove reminder',
          ),
        ],
      ],
    );
  }
}
