import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';
import 'package:water_it/features/plants/presentation/pages/plant_form_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static const int _maxPhotos = 4;
  final List<String> _photoPaths = [];
  bool _isPicking = false;

  Future<void> _takePhoto() async {
    if (_isPicking || _photoPaths.length >= _maxPhotos) {
      return;
    }

    setState(() {
      _isPicking = true;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked != null && mounted) {
        setState(() {
          _photoPaths.add(picked.path);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  void _addPlant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantFormPage(
          initialImagePaths: List.of(_photoPaths),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _photoPaths.clear();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhotos = _photoPaths.isNotEmpty;
    final canTakeMore = _photoPaths.length < _maxPhotos;

    return ListView(
      padding: EdgeInsets.only(
        left: spacing.lg,
        right: spacing.lg,
        top: spacing.lg,
        bottom: spacing.xxl,
      ),
      children: [
        Text(
          'Take up to $_maxPhotos photos of your plant, then add it to your collection.',
          style: textTheme.bodySmall,
        ),
        SizedBox(height: spacing.lg),
        if (!hasPhotos)
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_camera,
                      color: colorScheme.primary, size: 40),
                  SizedBox(height: spacing.sm),
                  Text('No photos yet', style: textTheme.labelMedium),
                ],
              ),
            ),
          ),
        if (hasPhotos)
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photoPaths.length,
              separatorBuilder: (_, __) => SizedBox(width: spacing.sm),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_photoPaths[index]),
                        width: 140,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        SizedBox(height: spacing.lg),
        if (canTakeMore)
          AppPrimaryButton(
            onPressed: _isPicking ? null : _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: _isPicking
                ? 'Opening camera...'
                : hasPhotos
                    ? 'Take Another Photo (${_photoPaths.length}/$_maxPhotos)'
                    : 'Take Photo',
          ),
        if (hasPhotos) ...[
          SizedBox(height: spacing.sm),
          OutlinedButton.icon(
            onPressed: _addPlant,
            icon: const Icon(Icons.add),
            label: const Text('Add Plant'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
