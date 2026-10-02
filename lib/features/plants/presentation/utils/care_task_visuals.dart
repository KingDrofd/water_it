import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/features/plants/domain/entities/care_task.dart';

/// Filled icon for a task type, as used across the M6 screens.
IconData careTaskGlyph(CareTaskType type) {
  switch (type) {
    case CareTaskType.water:
      return Icons.water_drop_rounded;
    case CareTaskType.fertilize:
      return Icons.compost_rounded;
    case CareTaskType.mist:
      return Icons.shower_rounded;
    case CareTaskType.repot:
      return Icons.yard_rounded;
    case CareTaskType.prune:
      return Icons.content_cut_rounded;
    case CareTaskType.custom:
      return Icons.task_alt_rounded;
  }
}

/// Warm types (feeding, repotting) read amber; the rest read green.
Color careTaskTint(CareTaskType type, AppPalette palette) {
  switch (type) {
    case CareTaskType.fertilize:
    case CareTaskType.repot:
      return palette.amber;
    case CareTaskType.water:
    case CareTaskType.mist:
    case CareTaskType.prune:
    case CareTaskType.custom:
      return palette.deep;
  }
}

/// Soft background for the icon tile behind [careTaskGlyph].
Color careTaskTileColor(CareTaskType type, AppPalette palette) {
  return careTaskTint(type, palette) == palette.amber
      ? palette.nudgeBg
      : palette.card2;
}
