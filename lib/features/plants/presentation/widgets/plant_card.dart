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

  const PlantCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.schedule,
    required this.layout,
    this.onTap,
    this.onLongPress,
    this.imagePath,
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

  const _CardText({
    required this.name,
    required this.subtitle,
    required this.schedule,
    required this.maxLines,
    required this.showSubtitle,
    required this.showSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          style: textTheme.titleSmall,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
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
