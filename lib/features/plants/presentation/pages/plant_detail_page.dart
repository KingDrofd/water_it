import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/features/plants/presentation/pages/plant_edit_page.dart';

class PlantDetailPage extends StatelessWidget {
  final String name;

  const PlantDetailPage({
    super.key,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {          
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
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).pop(),
                            size: 48,
                            radius: 12,
                          ),
                          AppBarIconButton(
                            icon: Icons.edit_outlined,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PlantEditPage(name: name),
                                ),
                              );
                            },
                            size: 48,
                            radius: 12,
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.sm),
                      _HeroImage(colorScheme: colorScheme),
                      SizedBox(height: spacing.lg),
                      Text(name, style: textTheme.headlineSmall),
                      SizedBox(height: spacing.xs),
                      Text('Epipremnum aureum', style: textTheme.bodySmall),
                      SizedBox(height: spacing.md),
                      Wrap(
                        spacing: spacing.sm,
                        runSpacing: spacing.sm,
                        children: [
                          _InfoChip(
                            icon: Icons.wb_sunny_outlined,
                            label: 'Bright indirect',
                          ),
                          _InfoChip(
                            icon: Icons.opacity_outlined,
                            label: 'Every 7 days',
                          ),
                          _InfoChip(
                            icon: Icons.terrain_outlined,
                            label: 'Loamy soil',
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.lg),
                      _SectionCard(
                        title: 'Overview',
                        child: Column(
                          children: const [
                            _KeyValueRow(label: 'Origin', value: 'French Polynesia'),
                            _KeyValueRow(label: 'Age', value: '2 years'),
                            _KeyValueRow(label: 'Type', value: 'Trailing vine'),
                          ],
                        ),
                      ),
                      SizedBox(height: spacing.md),
                      _SectionCard(
                        title: 'Care',
                        child: Column(
                          children: const [
                            _KeyValueRow(label: 'Light', value: 'Bright, indirect'),
                            _KeyValueRow(label: 'Water', value: 'Moderate'),
                            _KeyValueRow(label: 'Humidity', value: 'Average'),
                          ],
                        ),
                      ),
                      SizedBox(height: spacing.md),
                      _SectionCard(
                        title: 'Notes',
                        child: Text(
                          'Rotate weekly for even growth. Avoid direct sun.',
                          style: textTheme.bodySmall,
                        ),
                      ),
                      SizedBox(height: spacing.md),
                      _SectionCard(
                        title: 'Reminders',
                        child: Column(
                          children: const [
                            _ReminderRow(
                              title: 'Watering',
                              subtitle: 'Next in 3 days',
                            ),
                            _ReminderRow(
                              title: 'Fertilize',
                              subtitle: 'Next in 2 weeks',
                            ),
                          ],
                        ),
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
        },
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final ColorScheme colorScheme;

  const _HeroImage({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Icon(
          Icons.local_florist,
          size: 64,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: spacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          SizedBox(height: spacing.sm),
          child,
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodySmall),
          Text(value, style: textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ReminderRow({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.notifications_none, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyMedium),
                Text(subtitle, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
