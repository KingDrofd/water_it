import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/presentation/utils/reminder_formatters.dart';

String careTaskTypeLabel(CareTaskType type) {
  if (type == CareTaskType.custom) {
    return 'Custom';
  }
  final name = type.name;
  return name[0].toUpperCase() + name.substring(1);
}

IconData careTaskIcon(CareTaskType type) {
  switch (type) {
    case CareTaskType.water:
      return Icons.water_drop_outlined;
    case CareTaskType.fertilize:
      return Icons.eco_outlined;
    case CareTaskType.mist:
      return Icons.air;
    case CareTaskType.repot:
      return Icons.yard_outlined;
    case CareTaskType.prune:
      return Icons.content_cut;
    case CareTaskType.custom:
      return Icons.checklist;
  }
}

String formatCareTaskSchedule(CareTask task) {
  final timeLabel = task.preferredTime != null
      ? DateFormat('h:mm a').format(task.preferredTime!)
      : null;
  final String base;
  switch (task.scheduleType) {
    case CareScheduleType.weekly:
      base = task.weekdays.isEmpty
          ? 'No days selected'
          : formatWeekdays(task.weekdays);
    case CareScheduleType.interval:
      base = task.intervalDays == 1
          ? 'Every day'
          : 'Every ${task.intervalDays} days';
  }
  return timeLabel == null ? base : '$base - $timeLabel';
}

class CareTaskSection extends StatelessWidget {
  final List<CareTask> tasks;
  final VoidCallback onAdd;
  final ValueChanged<CareTask> onTapTask;

  const CareTaskSection({
    super.key,
    required this.tasks,
    required this.onAdd,
    required this.onTapTask,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tasks.isEmpty)
          Text('No care tasks yet.', style: textTheme.bodySmall)
        else
          for (final task in tasks)
            CareTaskRow(task: task, onTap: () => onTapTask(task)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add task'),
          ),
        ),
      ],
    );
  }
}

class CareTaskRow extends StatelessWidget {
  final CareTask task;
  final VoidCallback onTap;

  const CareTaskRow({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final muted = !task.active;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              careTaskIcon(task.type),
              size: 18,
              color: muted ? colorScheme.outline : colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: muted ? colorScheme.outline : null,
                    ),
                  ),
                  Text(
                    formatCareTaskSchedule(task),
                    style: textTheme.bodySmall?.copyWith(
                      color: muted ? colorScheme.outline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (muted)
              Text(
                'Paused',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

/// What the editor sheet resolved to: a task to save, or one to delete.
class CareTaskEditorResult {
  const CareTaskEditorResult.saved(this.task) : deleted = false;
  const CareTaskEditorResult.deleted(this.task) : deleted = true;

  final CareTask task;
  final bool deleted;
}

/// Opens the task editor for a new task (when [existing] is null) or an
/// existing one. Resolves to null when dismissed without saving.
Future<CareTaskEditorResult?> showCareTaskEditor(
  BuildContext context, {
  required String plantId,
  CareTask? existing,
}) {
  return showModalBottomSheet<CareTaskEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CareTaskEditorSheet(plantId: plantId, existing: existing),
  );
}

class _CareTaskEditorSheet extends StatefulWidget {
  final String plantId;
  final CareTask? existing;

  const _CareTaskEditorSheet({required this.plantId, this.existing});

  @override
  State<_CareTaskEditorSheet> createState() => _CareTaskEditorSheetState();
}

class _CareTaskEditorSheetState extends State<_CareTaskEditorSheet> {
  static const Uuid _uuid = Uuid();

  late CareTaskType _type;
  late CareScheduleType _scheduleType;
  late Set<int> _weekdays;
  late TextEditingController _customLabelController;
  late TextEditingController _intervalController;
  late TextEditingController _notesController;
  TimeOfDay? _preferredTime;
  late bool _active;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? CareTaskType.water;
    _scheduleType = existing?.scheduleType ?? CareScheduleType.weekly;
    _weekdays = {...?existing?.weekdays};
    _customLabelController =
        TextEditingController(text: existing?.customLabel ?? '');
    _intervalController = TextEditingController(
      text: existing != null && existing.intervalDays > 0
          ? '${existing.intervalDays}'
          : '7',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _preferredTime = existing?.preferredTime != null
        ? TimeOfDay.fromDateTime(existing!.preferredTime!)
        : null;
    _active = existing?.active ?? true;
  }

  @override
  void dispose() {
    _customLabelController.dispose();
    _intervalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _preferredTime = picked);
    }
  }

  void _save() {
    final customLabel = _customLabelController.text.trim();
    final intervalDays = int.tryParse(_intervalController.text.trim()) ?? 0;

    String? error;
    if (_type == CareTaskType.custom && customLabel.isEmpty) {
      error = 'Give the custom task a name.';
    } else if (_scheduleType == CareScheduleType.weekly && _weekdays.isEmpty) {
      error = 'Pick at least one day.';
    } else if (_scheduleType == CareScheduleType.interval && intervalDays < 1) {
      error = 'Interval must be at least 1 day.';
    }
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    final now = DateTime.now();
    final notes = _notesController.text.trim();
    final task = CareTask(
      id: widget.existing?.id ?? _uuid.v4(),
      plantId: widget.plantId,
      type: _type,
      customLabel: _type == CareTaskType.custom ? customLabel : null,
      scheduleType: _scheduleType,
      weekdays: _scheduleType == CareScheduleType.weekly
          ? (_weekdays.toList()..sort())
          : const [],
      intervalDays: intervalDays,
      preferredTime: _preferredTime != null
          ? DateTime(now.year, now.month, now.day, _preferredTime!.hour,
              _preferredTime!.minute)
          : null,
      notes: notes.isEmpty ? null : notes,
      active: _active,
      // Preserved on edit; stamped on create so a new task is never already
      // overdue for an occurrence that predates it.
      createdAt: widget.existing?.createdAt ?? now,
    );
    Navigator.of(context).pop(CareTaskEditorResult.saved(task));
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final existing = widget.existing;

    return Padding(
      padding: EdgeInsets.only(
        left: spacing.lg,
        right: spacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + spacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? 'New care task' : 'Edit care task',
              style: textTheme.titleMedium,
            ),
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.xs,
              children: [
                for (final type in CareTaskType.values)
                  ChoiceChip(
                    avatar: Icon(careTaskIcon(type), size: 18),
                    label: Text(careTaskTypeLabel(type)),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            if (_type == CareTaskType.custom) ...[
              SizedBox(height: spacing.sm),
              TextField(
                controller: _customLabelController,
                decoration: const InputDecoration(
                  labelText: 'Task name',
                  hintText: 'e.g. Rotate toward light',
                ),
              ),
            ],
            SizedBox(height: spacing.md),
            SegmentedButton<CareScheduleType>(
              segments: const [
                ButtonSegment(
                  value: CareScheduleType.weekly,
                  label: Text('Weekly'),
                ),
                ButtonSegment(
                  value: CareScheduleType.interval,
                  label: Text('Every N days'),
                ),
              ],
              selected: {_scheduleType},
              onSelectionChanged: (value) =>
                  setState(() => _scheduleType = value.first),
              showSelectedIcon: false,
            ),
            SizedBox(height: spacing.sm),
            if (_scheduleType == CareScheduleType.weekly)
              Wrap(
                spacing: spacing.xs,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(formatWeekdays([day])),
                      selected: _weekdays.contains(day),
                      onSelected: (selected) => setState(() {
                        selected ? _weekdays.add(day) : _weekdays.remove(day);
                      }),
                    ),
                ],
              )
            else
              Row(
                children: [
                  const Text('Every'),
                  SizedBox(width: spacing.sm),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _intervalController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  const Text('days, from the last completion'),
                ],
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(
                _preferredTime == null
                    ? 'Preferred time (9:00 AM default)'
                    : _preferredTime!.format(context),
              ),
              trailing: _preferredTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _preferredTime = null),
                    )
                  : null,
              onTap: _pickTime,
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            if (_validationError != null) ...[
              Text(
                _validationError!,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
              SizedBox(height: spacing.sm),
            ],
            Row(
              children: [
                if (existing != null)
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pop(CareTaskEditorResult.deleted(existing)),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: spacing.sm),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
