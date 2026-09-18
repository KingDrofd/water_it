import 'dart:io';

import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_spacing.dart';

enum PlantCardLayout { grid, list, wide }

class PlantCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String schedule;
  final PlantCardLayout layout;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? imagePath;
  final bool isOverdue;

  const PlantCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.schedule,
    required this.layout,
    this.onTap,
    this.onLongPress,
    this.imagePath,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final padding = layout == PlantCardLayout.grid ? 0.0 : spacing.md;
    final content = switch (layout) {
      PlantCardLayout.list => Row(
          children: [
            _ImagePlaceholder(
              size: 56,
              colorScheme: colorScheme,
              imagePath: imagePath,
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: _CardText(
                name: name,
                subtitle: subtitle,
                schedule: schedule,
                maxLines: 1,
                showSubtitle: true,
                showSchedule: false,
                isOverdue: isOverdue,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      PlantCardLayout.wide => Row(
          children: [
            _ImagePlaceholder(
              size: 84,
              colorScheme: colorScheme,
              imagePath: imagePath,
            ),
            SizedBox(width: spacing.md),
            Expanded(
              child: _CardText(
                name: name,
                subtitle: subtitle,
                schedule: schedule,
                maxLines: 2,
                showSubtitle: true,
                showSchedule: true,
                isOverdue: isOverdue,
              ),
            ),
          ],
        ),
      PlantCardLayout.grid => Stack(
          children: [
            Positioned.fill(
              child: _ImageBackground(
                colorScheme: colorScheme,
                imagePath: imagePath,
              ),
            ),
            Positioned(
              left: spacing.md,
              right: spacing.md,
              bottom: spacing.md,
              child: _CardText(
                name: name,
                subtitle: subtitle,
                schedule: schedule,
                maxLines: 1,
                showSubtitle: false,
                showSchedule: true,
              ),
            ),
            if (isOverdue)
              Positioned(
                top: spacing.sm,
                right: spacing.sm,
                child: const _OverdueBadge(),
              ),
          ],
        ),
    };

    return Material(
      color: colorScheme.surface,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: DefaultTextStyle.merge(
            style: textTheme.bodySmall,
            child: content,
          ),
        ),
      ),
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Overdue',
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double size;
  final ColorScheme colorScheme;
  final String? imagePath;

  const _ImagePlaceholder({
    required this.size,
    required this.colorScheme,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final image = imagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: image != null && image.isNotEmpty
          ? Image.file(
              File(image),
              height: size,
              width: size,
              fit: BoxFit.cover,
            )
          : Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_florist,
                color: colorScheme.primary,
              ),
            ),
    );
  }
}

class _ImageBackground extends StatelessWidget {
  final ColorScheme colorScheme;
  final String? imagePath;

  const _ImageBackground({
    required this.colorScheme,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final image = imagePath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: image != null && image.isNotEmpty
          ? Image.file(
              File(image),
              fit: BoxFit.cover,
            )
          : Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.local_florist,
                  size: 44,
                  color: colorScheme.primary,
                ),
              ),
            ),
    );
  }
}

class _CardText extends StatelessWidget {
  final String name;
  final String subtitle;
  final String schedule;
  final int maxLines;
  final bool showSubtitle;
  final bool showSchedule;
  final bool isOverdue;

  const _CardText({
    required this.name,
    required this.subtitle,
    required this.schedule,
    required this.maxLines,
    required this.showSubtitle,
    required this.showSchedule,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: textTheme.titleSmall,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOverdue) ...[
              const SizedBox(width: 6),
              const _OverdueBadge(),
            ],
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.bodySmall,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (showSchedule) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.opacity, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  schedule,
                  style: textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
