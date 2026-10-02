import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/pickers/app_picker_sheet.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/services/care_task_schedule.dart';
import 'package:water_it/features/plants/domain/usecases/get_rooms.dart';
import 'package:water_it/features/plants/presentation/bloc/care_log_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/care_task_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_detail_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/pages/plant_edit_page.dart';
import 'package:water_it/features/plants/presentation/utils/care_field_labels.dart';
import 'package:water_it/features/plants/presentation/utils/care_task_visuals.dart';
import 'package:water_it/features/plants/presentation/widgets/care_history_widgets.dart';
import 'package:water_it/features/plants/presentation/widgets/care_task_widgets.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_card.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_detail_widgets.dart';

class PlantDetailPage extends StatelessWidget {
  final String plantId;

  const PlantDetailPage({
    super.key,
    required this.plantId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PlantDetailCubit(getIt())..loadPlant(plantId),
        ),
        BlocProvider(
          create: (_) => CareLogCubit(getIt(), getIt())..load(plantId),
        ),
        BlocProvider(
          create: (_) => getIt<CareTaskCubit>()..load(plantId),
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<PlantDetailCubit, PlantDetailState>(
          builder: (context, state) {
            switch (state.status) {
              case PlantDetailStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case PlantDetailStatus.failure:
                return PlantDetailMessage(
                  title: 'Unable to load plant',
                  subtitle: state.errorMessage ?? 'Try again in a moment.',
                );
              case PlantDetailStatus.notFound:
                return const PlantDetailMessage(
                  title: 'Plant not found',
                  subtitle: 'It may have been deleted.',
                );
              case PlantDetailStatus.loaded:
                return _DetailBody(
                  plant: state.plant!,
                  plantId: plantId,
                );
              case PlantDetailStatus.initial:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}

enum _PlantMenuAction { edit, delete }

class _DetailBody extends StatelessWidget {
  final Plant plant;
  final String plantId;

  const _DetailBody({
    required this.plant,
    required this.plantId,
  });

  Future<void> _editTask(BuildContext context, [CareTask? task]) async {
    final taskCubit = context.read<CareTaskCubit>();
    final detailCubit = context.read<PlantDetailCubit>();
    final result = await showCareTaskEditor(
      context,
      plantId: plantId,
      existing: task,
    );
    if (result == null) {
      return;
    }
    if (result.deleted) {
      await taskCubit.delete(result.task);
    } else {
      await taskCubit.save(result.task);
    }
    // Tasks feed Home, library cards, and the schedule - refresh them too.
    await detailCubit.loadPlant(plantId);
    await getIt<PlantListCubit>().loadPlants();
  }

  Future<void> _markDone(BuildContext context, CareTask task) async {
    await context.read<CareLogCubit>().markDone(task);
    await getIt<PlantListCubit>().loadPlants();
  }

  Future<void> _showPlantMenu(BuildContext context) async {
    final choice = await showAppPicker<_PlantMenuAction>(
      context,
      title: plant.name,
      options: const [
        AppPickerOption(
          value: _PlantMenuAction.edit,
          label: 'Edit plant',
          subtitle: 'Photos, care details and room',
          icon: Icons.edit_rounded,
        ),
        AppPickerOption(
          value: _PlantMenuAction.delete,
          label: 'Delete plant',
          subtitle: 'Removes its tasks and history too',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
        ),
      ],
    );
    if (choice == null || !context.mounted) {
      return;
    }
    switch (choice.value) {
      case _PlantMenuAction.edit:
        await _editPlant(context);
      case _PlantMenuAction.delete:
        await _deletePlant(context);
    }
  }

  Future<void> _editPlant(BuildContext context) async {
    final detailCubit = context.read<PlantDetailCubit>();
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlantEditPage(plantId: plantId)),
    );
    if (didUpdate == true) {
      await detailCubit.loadPlant(plantId);
      await getIt<PlantListCubit>().loadPlants();
    }
  }

  Future<void> _deletePlant(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete plant?'),
        content: Text('Delete "${plant.name}", its tasks and its history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await getIt<PlantListCubit>().deletePlant(plantId);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);
    const heroHeight = 300.0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Hero(imagePath: _displayImagePath(plant)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RoundButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        _RoundButton(
                          icon: Icons.more_vert_rounded,
                          tooltip: 'More',
                          onTap: () => _showPlantMenu(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            // The sheet overlaps the bottom of the hero, as in the design.
            offset: const Offset(0, -28),
            child: Container(
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                spacing.lg,
                spacing.lg,
                spacing.lg,
                spacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: textTheme.displaySmall?.copyWith(
                      color: palette.deep,
                      fontSize: 32,
                    ),
                  ),
                  if (plant.scientificName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      plant.scientificName!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: palette.muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (plant.imagePaths.length > 1) ...[
                    SizedBox(height: spacing.md),
                    PlantImageStrip(paths: plant.imagePaths),
                  ],
                  SizedBox(height: spacing.lg),
                  _CareTiles(plant: plant),
                  SizedBox(height: spacing.lg),
                  _SectionHeader(
                    title: 'Care tasks',
                    actionLabel: 'Add task',
                    onAction: () => _editTask(context),
                  ),
                  const SizedBox(height: 10),
                  BlocBuilder<CareTaskCubit, CareTaskState>(
                    builder: (context, taskState) {
                      return BlocBuilder<CareLogCubit, CareLogState>(
                        builder: (context, logState) {
                          return _CareTaskList(
                            tasks: taskState.tasks,
                            latestByType: logState.latestByType,
                            isLogging: logState.isLogging,
                            onTapTask: (task) => _editTask(context, task),
                            onMarkDone: (task) => _markDone(context, task),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: spacing.lg),
                  const _SectionHeader(title: 'Care history'),
                  const SizedBox(height: 6),
                  BlocBuilder<CareTaskCubit, CareTaskState>(
                    builder: (context, taskState) {
                      return BlocBuilder<CareLogCubit, CareLogState>(
                        builder: (context, logState) => CareHistorySection(
                          events: logState.events,
                          taskLabels: {
                            for (final t in taskState.tasks) t.id: t.label,
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(height: spacing.lg),
                  _AboutSection(plant: plant),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final image = imagePath;
    if (image == null || image.isEmpty) {
      return const PlantPhotoPlaceholder(iconSize: 64);
    }
    return Image.file(
      File(image),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const PlantPhotoPlaceholder(iconSize: 64),
    );
  }
}

/// Floating circular control drawn over the hero photo.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final circle = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: palette.ink),
    );
    if (onTap == null) {
      return circle;
    }
    return Tooltip(
      message: tooltip,
      child: InkResponse(onTap: onTap, radius: 26, child: circle),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Lighting / Watering / Soil tiles from the structured care fields.
class _CareTiles extends StatelessWidget {
  const _CareTiles({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: _CareTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: palette.amber,
            label: 'Lighting',
            value: plant.preferredLighting?.label,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CareTile(
            icon: Icons.water_drop_rounded,
            iconColor: palette.deep,
            label: 'Watering',
            value: plant.wateringLevel?.label,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CareTile(
            icon: Icons.grass_rounded,
            iconColor: palette.deep,
            label: 'Soil',
            value: plant.soilType?.label,
          ),
        ),
      ],
    );
  }
}

class _CareTile extends StatelessWidget {
  const _CareTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: palette.muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value ?? 'Not set',
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(
              color: value == null ? palette.muted : palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Care tasks with a Mark done button each - filled when the task needs
/// doing now, outlined otherwise.
class _CareTaskList extends StatelessWidget {
  const _CareTaskList({
    required this.tasks,
    required this.latestByType,
    required this.isLogging,
    required this.onTapTask,
    required this.onMarkDone,
  });

  final List<CareTask> tasks;
  final Map<String, DateTime> latestByType;
  final bool isLogging;
  final ValueChanged<CareTask> onTapTask;
  final ValueChanged<CareTask> onMarkDone;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    if (tasks.isEmpty) {
      return Text(
        'No care tasks yet. Add one to get reminders.',
        style: textTheme.bodySmall?.copyWith(color: palette.muted),
      );
    }
    final now = DateTime.now();
    return Column(
      children: [
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TaskRow(
              task: task,
              status: CareTaskSchedule.status(
                task,
                latestByType[task.type.name],
                now,
              ),
              enabled: !isLogging,
              onTap: () => onTapTask(task),
              onMarkDone: () => onMarkDone(task),
            ),
          ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.status,
    required this.enabled,
    required this.onTap,
    required this.onMarkDone,
  });

  final CareTask task;
  final TaskStatus? status;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final paused = !task.active;
    final due = status?.needsCare ?? false;
    final overdue = status?.state == TaskDueState.overdue;

    return Material(
      color: palette.card,
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
                  color: careTaskTileColor(task.type, palette),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  careTaskGlyph(task.type),
                  color:
                      paused ? palette.muted : careTaskTint(task.type, palette),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.label,
                      style: textTheme.titleSmall?.copyWith(
                        color: paused ? palette.muted : null,
                      ),
                    ),
                    Text(
                      paused ? 'Paused' : formatCareTaskSchedule(task),
                      style: textTheme.bodySmall?.copyWith(
                        color: overdue ? palette.overdueInk : palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!paused) ...[
                const SizedBox(width: 8),
                due
                    ? FilledButton.icon(
                        onPressed: enabled ? onMarkDone : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Mark done'),
                        style: overdue
                            ? FilledButton.styleFrom(
                                backgroundColor: palette.overdueInk,
                                foregroundColor: palette.overdueBg,
                              )
                            : null,
                      )
                    : OutlinedButton.icon(
                        onPressed: enabled ? onMarkDone : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Mark done'),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Origin, age, room and notes, below the care sections.
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final notes = [
      plant.careNotes?.trim(),
      plant.description?.trim(),
    ].whereType<String>().where((n) => n.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          PlantKeyValueRow(label: 'Origin', value: plant.origin ?? 'Unknown'),
          PlantKeyValueRow(
            label: 'Age',
            value: plant.ageMonths != null
                ? '${plant.ageMonths} months'
                : 'Unknown',
          ),
          if (plant.roomId != null)
            FutureBuilder<List<Room>>(
              future: getIt<GetRooms>()(),
              builder: (context, snapshot) {
                String roomName = 'Unassigned';
                for (final room in snapshot.data ?? const <Room>[]) {
                  if (room.id == plant.roomId) {
                    roomName =
                        room.isOutdoor ? '${room.name} (outdoor)' : room.name;
                    break;
                  }
                }
                return PlantKeyValueRow(label: 'Room', value: roomName);
              },
            ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  note,
                  style: textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String? _displayImagePath(Plant plant) {
  if (plant.imagePaths.isEmpty) {
    return null;
  }
  if (!plant.useRandomImage) {
    return plant.imagePaths.first;
  }
  final index = plant.id.hashCode.abs() % plant.imagePaths.length;
  return plant.imagePaths[index];
}
