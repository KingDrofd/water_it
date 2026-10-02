import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/plants/presentation/pages/plant_form_page.dart';

enum _PlantSource { camera, gallery, manual }

/// Opens the Add Plant source menu, then the form pre-filled with whatever
/// photos the chosen source produced. Completes once the form is closed.
Future<void> showAddPlantSheet(BuildContext context) async {
  final source = await showModalBottomSheet<_PlantSource>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _AddPlantSheet(),
  );
  if (source == null || !context.mounted) {
    return;
  }

  final photos = await _pickPhotos(source);
  if (photos == null || !context.mounted) {
    return; // Camera or gallery dismissed without choosing anything.
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PlantFormPage(initialImagePaths: photos),
    ),
  );
}

/// Photos for [source]: empty for manual entry, null when the user backs out
/// of the camera or gallery so nothing opens.
Future<List<String>?> _pickPhotos(_PlantSource source) async {
  final picker = ImagePicker();
  switch (source) {
    case _PlantSource.manual:
      return const [];
    case _PlantSource.camera:
      final photo = await picker.pickImage(source: ImageSource.camera);
      return photo == null ? null : [photo.path];
    case _PlantSource.gallery:
      final photos = await picker.pickMultiImage(limit: 4);
      return photos.isEmpty ? null : photos.map((p) => p.path).toList();
  }
}

class _AddPlantSheet extends StatelessWidget {
  const _AddPlantSheet();

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.lg,
          0,
          spacing.lg,
          spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add a plant', style: textTheme.titleMedium),
            SizedBox(height: spacing.md),
            const _SourceTile(
              icon: Icons.photo_camera_rounded,
              title: 'Take a photo',
              subtitle: 'Snap your plant, then fill in the details',
              source: _PlantSource.camera,
            ),
            SizedBox(height: spacing.sm),
            const _SourceTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose from gallery',
              subtitle: 'Up to 4 photos you already have',
              source: _PlantSource.gallery,
            ),
            SizedBox(height: spacing.sm),
            const _SourceTile(
              icon: Icons.edit_note_rounded,
              title: 'Enter manually',
              subtitle: 'Add photos later if you like',
              source: _PlantSource.manual,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.source,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _PlantSource source;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: palette.bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pop(source),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.card2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: palette.deep),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall
                          ?.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}
