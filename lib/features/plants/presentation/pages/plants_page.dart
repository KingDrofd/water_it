import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/layout/app_breakpoints.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/pages/plant_detail_page.dart';
import 'package:water_it/features/plants/presentation/utils/reminder_formatters.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_card.dart';

enum PlantListView { gridOne, gridTwo, list }

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  PlantListView _view = PlantListView.gridTwo;

  void _setView(PlantListView view) {
    setState(() {
      _view = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gutter = AppLayout.gutter(width);
        final listState = context.watch<PlantListCubit>().state;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: spacing.lg,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: spacing.md),
                child: _ViewToggle(
                  selected: _view,
                  onChanged: _setView,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: spacing.xxl,
              ),
              sliver: _buildBody(width, gutter, listState),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(double width, double gutter, PlantListState state) {
    switch (state.status) {
      case PlantListStatus.loading:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        );
      case PlantListStatus.failure:
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            title: 'Unable to load plants',
            subtitle: state.errorMessage ?? 'Try again in a moment.',
          ),
        );
      case PlantListStatus.empty:
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            title: 'No plants yet',
            subtitle: 'Tap the + button to add your first plant.',
          ),
        );
      case PlantListStatus.initial:
      case PlantListStatus.loaded:
        final plants = state.plants;
        if (plants.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              title: 'No plants yet',
              subtitle: 'Tap the + button to add your first plant.',
            ),
          );
        }
        switch (_view) {
          case PlantListView.list:
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final plant = plants[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: gutter),
                    child: PlantCard(
                      name: plant.name,
                      subtitle: _plantSubtitle(plant),
                      schedule: _plantSchedule(plant),
                      layout: PlantCardLayout.list,
                      onTap: () => _openDetail(context, plant),
                      onLongPress: () => _confirmDelete(context, plant),
                      imagePath: _displayImagePath(plant),
                    ),
                  );
                },
                childCount: plants.length,
              ),
            );
          case PlantListView.gridOne:
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final plant = plants[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: gutter),
                    child: PlantCard(
                      name: plant.name,
                      subtitle: _plantSubtitle(plant),
                      schedule: _plantSchedule(plant),
                      layout: PlantCardLayout.wide,
                      onTap: () => _openDetail(context, plant),
                      onLongPress: () => _confirmDelete(context, plant),
                      imagePath: _displayImagePath(plant),
                    ),
                  );
                },
                childCount: plants.length,
              ),
            );
          case PlantListView.gridTwo:
            final columns = _columnsForWidth(width, _view);
            const aspectRatio = 0.85;

            return SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final plant = plants[index];
                  return PlantCard(
                    name: plant.name,
                    subtitle: _plantSubtitle(plant),
                    schedule: _plantSchedule(plant),
                    layout: PlantCardLayout.grid,
                    onTap: () => _openDetail(context, plant),
                    onLongPress: () => _confirmDelete(context, plant),
                    imagePath: _displayImagePath(plant),
                  );
                },
                childCount: plants.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: gutter,
                mainAxisSpacing: gutter,
                childAspectRatio: aspectRatio,
              ),
            );
        }
    }
  }

  int _columnsForWidth(double width, PlantListView view) {
    switch (AppBreakpoints.sizeClass(width)) {
      case AppSizeClass.compact:
        return 2;
      case AppSizeClass.medium:
        return 3;
      case AppSizeClass.expanded:
        return 4;
    }
  }

  String _plantSubtitle(Plant plant) {
    return plant.preferredLighting ??
        plant.scientificName ??
        plant.wateringLevel ??
        'No lighting details yet';
  }

  String _plantSchedule(Plant plant) {
    final reminders = plant.reminders;
    if (reminders.isNotEmpty) {
      return formatReminderSubtitle(reminders.first);
    }
    return plant.wateringLevel ?? 'Set a watering schedule';
  }

  void _openDetail(BuildContext context, Plant plant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantDetailPage(plantId: plant.id),
      ),
    );
  }

  

  String? _displayImagePath(Plant plant) {
    if (plant.imagePaths.isEmpty) {
      return null;
    }
    if (!plant.useRandomImage) {
      return plant.imagePaths.first;
    }
    final index = _stableImageIndex(plant);
    return plant.imagePaths[index];
  }

  int _stableImageIndex(Plant plant) {
    if (plant.imagePaths.isEmpty) {
      return 0;
    }
    return plant.id.hashCode.abs() % plant.imagePaths.length;
  }

  Future<void> _confirmDelete(BuildContext context, Plant plant) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete plant?'),
          content: Text('Delete "${plant.name}" and its reminders?'),
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
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      context.read<PlantListCubit>().deletePlant(plant.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final PlantListView selected;
  final ValueChanged<PlantListView> onChanged;

  const _ViewToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: SegmentedButton<PlantListView>(
        segments: const [
          ButtonSegment(
            value: PlantListView.gridOne,
            icon: Icon(Icons.view_agenda_outlined),
            label: Text('Single'),
          ),
          ButtonSegment(
            value: PlantListView.gridTwo,
            icon: Icon(Icons.grid_view_outlined),
            label: Text('Grid'),
          ),
          ButtonSegment(
            value: PlantListView.list,
            icon: Icon(Icons.view_list_outlined),
            label: Text('List'),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (value) => onChanged(value.first),
        showSelectedIcon: false,
      ),
    );
  }
}
