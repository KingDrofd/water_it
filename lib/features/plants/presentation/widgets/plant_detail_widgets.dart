import 'dart:io';

import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/presentation/utils/reminder_formatters.dart';

class PlantDetailMessage extends StatelessWidget {
  final String title;
  final String subtitle;

  const PlantDetailMessage({
    super.key,
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

class PlantHeroImage extends StatelessWidget {
  final ColorScheme colorScheme;
  final String? imagePath;

  const PlantHeroImage({
    super.key,
    required this.colorScheme,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final image = imagePath;

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: image != null && image.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  File(image),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(
                Icons.local_florist,
                size: 64,
                color: colorScheme.primary,
              ),
      ),
    );
  }
}

class PlantImageStrip extends StatelessWidget {
  final List<String> paths;

  const PlantImageStrip({
    super.key,
    required this.paths,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing.sm),
        itemBuilder: (context, index) {
          final path = paths[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

class PlantInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const PlantInfoChip({
    super.key,
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

class PlantSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const PlantSectionCard({
    super.key,
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

class PlantKeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const PlantKeyValueRow({
    super.key,
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

class PlantDetailChips extends StatelessWidget {
  final Plant plant;

  const PlantDetailChips({
    super.key,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final chips = <Widget>[];

    void addChip(IconData icon, String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      chips.add(PlantInfoChip(icon: icon, label: trimmed));
    }

    addChip(Icons.wb_sunny_outlined, plant.preferredLighting);
    addChip(
      Icons.opacity_outlined,
      plant.reminders.isNotEmpty
          ? formatReminderSubtitle(plant.reminders.first)
          : plant.wateringLevel,
    );
    addChip(Icons.terrain_outlined, plant.soilType);

    if (chips.isEmpty) {
      return Text(
        'Add care details to see quick highlights here.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: chips,
    );
  }
}

class PlantReminderSection extends StatelessWidget {
  final List<WateringReminder> reminders;

  const PlantReminderSection({
    super.key,
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return Text(
        'No reminders yet.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      children: [
        for (final reminder in reminders)
          PlantReminderRow(
            title: reminder.notes?.trim().isNotEmpty == true
                ? reminder.notes!.trim()
                : 'Reminder',
            subtitle: formatReminderSubtitle(reminder),
          ),
      ],
    );
  }
}

class PlantReminderRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const PlantReminderRow({
    super.key,
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
