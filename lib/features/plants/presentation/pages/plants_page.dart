import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_breakpoints.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
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

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: AppLayout.navBarInset(
                  width,
                  spacing: spacing.xxl + spacing.xxl,
                ),
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
                bottom: AppLayout.navBarInset(
                  width,
                  spacing: spacing.xxl,
                ),
              ),
              sliver: _buildBody(width, gutter),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(double width, double gutter) {
    switch (_view) {
      case PlantListView.list:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: gutter),
                child: PlantCard(
                  name: _plantName(index),
                  subtitle: _plantSubtitle(index),
                  schedule: _plantSchedule(index),
                  layout: PlantCardLayout.list,
                  onTap: () {},
                ),
              );
            },
            childCount: 20,
          ),
        );
      case PlantListView.gridOne:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: gutter),
                child: PlantCard(
                  name: _plantName(index),
                  subtitle: _plantSubtitle(index),
                  schedule: _plantSchedule(index),
                  layout: PlantCardLayout.wide,
                  onTap: () {},
                ),
              );
            },
            childCount: 20,
          ),
        );
      case PlantListView.gridTwo:
        final columns = _columnsForWidth(width, _view);
        const aspectRatio = 0.85;

        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return PlantCard(
                name: _plantName(index),
                subtitle: _plantSubtitle(index),
                schedule: _plantSchedule(index),
                layout: PlantCardLayout.grid,
                onTap: () {},
              );
            },
            childCount: 20,
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

  String _plantName(int index) {
    const names = [
      'Golden Pothos',
      'Snake Plant',
      'Monstera',
      'ZZ Plant',
      'Fiddle Leaf',
      'Peace Lily',
      'Aloe Vera',
      'Rubber Plant',
    ];
    return names[index % names.length];
  }

  String _plantSubtitle(int index) {
    const subtitles = [
      'Bright, indirect light',
      'Low light tolerant',
      'Weekly misting',
      'North window',
    ];
    return subtitles[index % subtitles.length];
  }

  String _plantSchedule(int index) {
    const schedules = [
      'Every 7 days',
      'Every 10 days',
      'Every 14 days',
    ];
    return schedules[index % schedules.length];
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
