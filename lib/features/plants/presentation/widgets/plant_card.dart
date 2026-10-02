import 'dart:io';

import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';
import 'package:water_it/features/plants/presentation/utils/care_task_visuals.dart';

enum PlantCardLayout { grid, list, wide }

class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.layout,
    this.status,
    this.statusType,
    this.isOverdue = false,
    this.onTap,
    this.onLongPress,
    this.imagePath,
  });

  final String name;

  /// Secondary line for the list and wide layouts (scientific name, room).
  final String subtitle;

  /// Next care task, e.g. "Water in 2 days"; null when the plant has none.
  final String? status;
  final CareTaskType? statusType;
  final bool isOverdue;
  final PlantCardLayout layout;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final content = switch (layout) {
      PlantCardLayout.grid => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PlantImage(imagePath: imagePath, iconSize: 40),
                  if (isOverdue)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: _OverdueBadge(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _CardText(
                name: name,
                status: status,
                statusType: statusType,
                isOverdue: isOverdue,
              ),
            ),
          ],
        ),
      PlantCardLayout.list => Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 58,
                  child: _PlantImage(imagePath: imagePath, iconSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CardText(
                  name: name,
                  subtitle: subtitle,
                  status: status,
                  statusType: statusType,
                  isOverdue: isOverdue,
                  showBadge: true,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
          ),
        ),
      PlantCardLayout.wide => Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox.square(
                  dimension: 88,
                  child: _PlantImage(imagePath: imagePath, iconSize: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CardText(
                  name: name,
                  subtitle: subtitle,
                  status: status,
                  statusType: statusType,
                  isOverdue: isOverdue,
                  showBadge: true,
                ),
              ),
            ],
          ),
        ),
    };

    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      ),
    );
  }
}

class _CardText extends StatelessWidget {
  const _CardText({
    required this.name,
    required this.isOverdue,
    this.subtitle,
    this.status,
    this.statusType,
    this.showBadge = false,
  });

  final String name;
  final String? subtitle;
  final String? status;
  final CareTaskType? statusType;
  final bool isOverdue;

  /// Grid shows the badge on the photo; the row layouts show it by the name.
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final statusColor = isOverdue ? palette.overdueInk : palette.muted;
    final iconColor = isOverdue
        ? palette.overdueInk
        : statusType == null
            ? palette.muted
            : careTaskTint(statusType!, palette);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showBadge && isOverdue) ...[
              const SizedBox(width: 6),
              const _OverdueBadge(),
            ],
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(color: palette.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              statusType == null
                  ? Icons.event_available_rounded
                  : careTaskGlyph(statusType!),
              size: 14,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                status ?? 'No care tasks yet',
                style: textTheme.bodySmall?.copyWith(color: statusColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverdueBadge extends StatelessWidget {
  const _OverdueBadge();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.overdueInk,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'OVERDUE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: palette.overdueBg,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

/// The plant's photo, or the design's striped placeholder when there is none.
class _PlantImage extends StatelessWidget {
  const _PlantImage({required this.imagePath, required this.iconSize});

  final String? imagePath;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final image = imagePath;
    if (image != null && image.isNotEmpty) {
      return Image.file(
        File(image),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => PlantPhotoPlaceholder(iconSize: iconSize),
      );
    }
    return PlantPhotoPlaceholder(iconSize: iconSize);
  }
}

/// Diagonal-stripe placeholder from the M6 mockups, used wherever a plant
/// has no photo.
class PlantPhotoPlaceholder extends StatelessWidget {
  const PlantPhotoPlaceholder({super.key, this.iconSize = 40});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return CustomPaint(
      painter: _StripePainter(palette.placeholder1, palette.placeholder2),
      child: Center(
        child: Icon(
          Icons.local_florist_rounded,
          size: iconSize,
          color: palette.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.a, this.b);

  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = b);
    final stripe = Paint()
      ..color = a
      ..strokeWidth = 10;
    const gap = 22.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.a != a || old.b != b;
}
