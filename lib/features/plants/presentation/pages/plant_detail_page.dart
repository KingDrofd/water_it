import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_detail_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/pages/plant_edit_page.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_detail_widgets.dart';

class PlantDetailPage extends StatelessWidget {
  final String plantId;

  const PlantDetailPage({
    super.key,
    required this.plantId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlantDetailCubit(getIt())..loadPlant(plantId),
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

class _DetailBody extends StatelessWidget {
  final Plant plant;
  final String plantId;

  const _DetailBody({
    required this.plant,
    required this.plantId,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: spacing.xxl),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppBarIconButton(
                      icon: Icons.chevron_left,
                      onTap: () => Navigator.of(context).pop(),
                      size: 48,
                      radius: 12,
                      iconSize: 30,
                    ),
                    AppBarIconButton(
                      icon: Icons.edit_outlined,
                      onTap: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => PlantEditPage(plantId: plantId),
                              ),
                            )
                            .then((didUpdate) {
                          if (didUpdate == true) {
                            context.read<PlantDetailCubit>().loadPlant(plantId);
                            getIt<PlantListCubit>().loadPlants();
                          }
                        });
                      },
                      size: 48,
                      radius: 12,
                    ),
                  ],
                ),
                SizedBox(height: spacing.sm),
                PlantHeroImage(
                  colorScheme: colorScheme,
                  imagePath: _displayImagePath(plant),
                ),
                if (plant.imagePaths.length > 1) ...[
                  SizedBox(height: spacing.sm),
                  PlantImageStrip(paths: plant.imagePaths),
                ],
                SizedBox(height: spacing.lg),
                Text(
                  plant.name,
                  style: textTheme.displaySmall?.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.xs),
                Text(
                  plant.scientificName ?? 'Scientific name not set',
                  style: textTheme.bodySmall,
                ),
                SizedBox(height: spacing.md),
                PlantDetailChips(plant: plant),
                SizedBox(height: spacing.lg),
                PlantSectionCard(
                  title: 'Overview',
                  child: Column(
                    children: [
                      PlantKeyValueRow(
                        label: 'Origin',
                        value: plant.origin ?? 'Unknown',
                      ),
                      PlantKeyValueRow(
                        label: 'Age',
                        value: plant.ageMonths != null
                            ? '${plant.ageMonths} months'
                            : 'Unknown',
                      ),
                      PlantKeyValueRow(
                        label: 'Scientific',
                        value: plant.scientificName ?? 'Unknown',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.md),
                PlantSectionCard(
                  title: 'Care',
                  child: Column(
                    children: [
                      PlantKeyValueRow(
                        label: 'Light',
                        value: plant.preferredLighting ?? 'Not set',
                      ),
                      PlantKeyValueRow(
                        label: 'Water',
                        value: plant.wateringLevel ?? 'Not set',
                      ),
                      PlantKeyValueRow(
                        label: 'Soil',
                        value: plant.soilType ?? 'Not set',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.md),
                PlantSectionCard(
                  title: 'Notes',
                  child: Text(
                    plant.description ?? 'No notes yet.',
                    style: textTheme.bodySmall,
                  ),
                ),
                SizedBox(height: spacing.md),
                PlantSectionCard(
                  title: 'Reminders',
                  child: PlantReminderSection(reminders: plant.reminders),
                ),
                SizedBox(height: spacing.xxl),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: spacing.xl),
        ),
      ],
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
