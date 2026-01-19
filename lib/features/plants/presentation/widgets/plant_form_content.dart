import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_image_picker.dart';

class PlantFormContent extends StatelessWidget {
  final String imageLabel;
  final List<String> imagePaths;
  final bool useRandomImage;
  final VoidCallback onAddImage;
  final ValueChanged<String> onRemoveImage;
  final ValueChanged<String> onSelectPrimary;
  final ValueChanged<bool> onRandomChanged;
  final TextEditingController nameController;
  final TextEditingController scientificController;
  final TextEditingController ageController;
  final TextEditingController descriptionController;
  final TextEditingController lightingController;
  final TextEditingController wateringController;
  final TextEditingController soilController;
  final TextEditingController originController;
  final TextStyle? labelStyle;
  final List<Widget> reminderInputs;
  final VoidCallback onAddReminder;
  final Widget saveButton;

  const PlantFormContent({
    super.key,
    required this.imageLabel,
    required this.imagePaths,
    required this.useRandomImage,
    required this.onAddImage,
    required this.onRemoveImage,
    required this.onSelectPrimary,
    required this.onRandomChanged,
    required this.nameController,
    required this.scientificController,
    required this.ageController,
    required this.descriptionController,
    required this.lightingController,
    required this.wateringController,
    required this.soilController,
    required this.originController,
    required this.labelStyle,
    required this.reminderInputs,
    required this.onAddReminder,
    required this.saveButton,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlantImagePickerCard(
          imagePaths: imagePaths,
          onAdd: onAddImage,
          onRemove: onRemoveImage,
          onSelectPrimary: onSelectPrimary,
          useRandomImage: useRandomImage,
          onRandomChanged: onRandomChanged,
          label: imageLabel,
        ),
        SizedBox(height: spacing.xl),
        Text(
          'Basics',
          style: textTheme.displaySmall?.copyWith(fontSize: 22),
        ),
        SizedBox(height: spacing.sm),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Golden pothos',
            labelStyle: labelStyle,
          ),
        ),
        SizedBox(height: spacing.sm),
        _FieldRow(
          left: TextField(
            controller: scientificController,
            decoration: InputDecoration(
              labelText: 'Scientific name',
              hintText: 'Epipremnum aureum',
              labelStyle: labelStyle,
            ),
          ),
          right: TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Age (months)',
              hintText: '24',
              labelStyle: labelStyle,
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Optional notes about this plant',
            labelStyle: labelStyle,
          ),
          maxLines: 3,
        ),
        SizedBox(height: spacing.xl),
        Text(
          'Care',
          style: textTheme.displaySmall?.copyWith(fontSize: 22),
        ),
        SizedBox(height: spacing.sm),
        _FieldRow(
          left: TextField(
            controller: lightingController,
            decoration: InputDecoration(
              labelText: 'Preferred lighting',
              hintText: 'Bright indirect',
              labelStyle: labelStyle,
            ),
          ),
          right: TextField(
            controller: wateringController,
            decoration: InputDecoration(
              labelText: 'Watering level',
              hintText: 'Moderate',
              labelStyle: labelStyle,
            ),
          ),
        ),
        SizedBox(height: spacing.sm),
        _FieldRow(
          left: TextField(
            controller: soilController,
            decoration: InputDecoration(
              labelText: 'Soil type',
              hintText: 'Loamy soil',
              labelStyle: labelStyle,
            ),
          ),
          right: TextField(
            controller: originController,
            decoration: InputDecoration(
              labelText: 'Origin',
              hintText: 'French Polynesia',
              labelStyle: labelStyle,
            ),
          ),
        ),
        SizedBox(height: spacing.xl),
        Text(
          'Reminders',
          style: textTheme.displaySmall?.copyWith(fontSize: 22),
        ),
        SizedBox(height: spacing.md),
        ...reminderInputs,
        TextButton.icon(
          onPressed: onAddReminder,
          icon: const Icon(Icons.add),
          label: const Text('Add reminder'),
        ),
        SizedBox(height: spacing.xl),
        saveButton,
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _FieldRow({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final isWide = MediaQuery.of(context).size.width >= 600;
    if (isWide) {
      return Row(
        children: [
          Expanded(child: left),
          SizedBox(width: spacing.md),
          Expanded(child: right),
        ],
      );
    }
    return Column(
      children: [
        left,
        SizedBox(height: spacing.sm),
        right,
      ],
    );
  }
}
