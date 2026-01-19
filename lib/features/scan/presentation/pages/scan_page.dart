import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';
import 'package:water_it/features/plants/presentation/pages/plant_form_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  Uint8List? _imageBytes;
  String? _imageName;
  String? _imagePath;
  bool _isPicking = false;

  Future<void> _takePhoto() async {
    if (_isPicking) {
      return;
    }

    setState(() {
      _isPicking = true;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
        _imagePath = picked.path;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  void _showScanUnderConstruction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Scan Now auto-fill is still under construction.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return ListView(
          padding: EdgeInsets.only(
            left: spacing.lg,
            right: spacing.lg,
            bottom: AppLayout.navBarInset(width, spacing: spacing.xxl),
          ),
          children: [
            SizedBox(height: AppLayout.navBarInset(width, spacing: spacing.xxl + spacing.xxl)),
            Text('Scan Plant', style: textTheme.headlineSmall),
            SizedBox(height: spacing.sm),
            Text(
              'Take a clear photo of the plant to identify it later.',
              style: textTheme.bodySmall,
            ),
            SizedBox(height: spacing.lg),
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline),
              ),
              child: _imageBytes == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera, color: colorScheme.primary, size: 40),
                          SizedBox(height: spacing.sm),
                          Text('No image yet', style: textTheme.labelMedium),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),
            SizedBox(height: spacing.lg),
            AppPrimaryButton(
              onPressed: _isPicking ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: _isPicking ? 'Opening camera...' : 'Take Photo',
            ),
            SizedBox(height: spacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _imageBytes == null ? null : _showScanUnderConstruction,
                    icon: const Icon(Icons.search),
                    label: const Text('Scan Now'),
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
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlantFormPage(
                            initialImagePath: _imagePath,
                          ),
                        ),
                      );
                    },
                    child: const Text('Add New Plant'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
