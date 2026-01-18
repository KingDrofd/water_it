import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';

class PlantFormPage extends StatelessWidget {
  const PlantFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppBarIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                    size: 48,
                    radius: 12,
                  ),
                  SizedBox(width: spacing.md),
                  Text('Add Plant', style: textTheme.headlineSmall),
                ],
              ),
              SizedBox(height: spacing.lg),
              Expanded(
                child: ListView(
                  children: [
                    _ImagePickerCard(),
                    SizedBox(height: spacing.lg),
                    Text('Basics', style: textTheme.titleMedium),
                    SizedBox(height: spacing.sm),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Golden pothos',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Scientific name',
                        hintText: 'Epipremnum aureum',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional notes about this plant',
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: spacing.lg),
                    Text('Care', style: textTheme.titleMedium),
                    SizedBox(height: spacing.sm),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Preferred lighting',
                        hintText: 'Bright indirect',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Soil type',
                        hintText: 'Loamy soil',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Watering level',
                        hintText: 'Moderate',
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    Text('Metadata', style: textTheme.titleMedium),
                    SizedBox(height: spacing.sm),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Origin',
                        hintText: 'French Polynesia',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Age',
                        hintText: '2 years',
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    Text('Reminders', style: textTheme.titleMedium),
                    SizedBox(height: spacing.sm),
                    _ReminderRow(label: 'Water every', value: '7 days'),
                    SizedBox(height: spacing.sm),
                    _ReminderRow(label: 'Fertilize every', value: '30 days'),
                    SizedBox(height: spacing.lg),
                    AppPrimaryButton(
                      onPressed: () {},
                      label: 'Save Plant',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: colorScheme.primary),
            SizedBox(height: spacing.sm),
            Text('Add images', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReminderRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: textTheme.bodyMedium),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(value, style: textTheme.labelMedium),
        ),
      ],
    );
  }
}
