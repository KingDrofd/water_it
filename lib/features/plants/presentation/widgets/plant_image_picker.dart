import 'dart:io';

import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_spacing.dart';

class PlantImagePickerCard extends StatelessWidget {
  final List<String> imagePaths;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onSelectPrimary;
  final bool useRandomImage;
  final ValueChanged<bool> onRandomChanged;
  final String label;

  const PlantImagePickerCard({
    super.key,
    required this.imagePaths,
    required this.onAdd,
    required this.onRemove,
    required this.onSelectPrimary,
    required this.useRandomImage,
    required this.onRandomChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colorScheme = Theme.of(context).colorScheme;
    final inputFill = Theme.of(context).inputDecorationTheme.fillColor ??
        const Color(0xFFF2F2F2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onAdd,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: inputFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: colorScheme.primary),
                  SizedBox(height: spacing.sm),
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                'Random image each time',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Switch.adaptive(
              value: useRandomImage,
              onChanged: onRandomChanged,
            ),
          ],
        ),
        Text(
          useRandomImage
              ? 'Showing a random image on cards and detail.'
              : 'Tap a thumbnail to set the primary image.',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        if (imagePaths.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.sm,
            children: imagePaths.map((path) {
              final isPrimary = path == imagePaths.first;
              return GestureDetector(
                onTap: useRandomImage ? null : () => onSelectPrimary(path),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(path),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isPrimary && !useRandomImage)
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: InkWell(
                        onTap: () => onRemove(path),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
