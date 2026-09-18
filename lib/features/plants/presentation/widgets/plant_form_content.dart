import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/plants/domain/entities/care_profile.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/presentation/utils/care_field_labels.dart';
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
  final LightingLevel? lighting;
  final ValueChanged<LightingLevel?> onLightingChanged;
  final WateringLevel? watering;
  final ValueChanged<WateringLevel?> onWateringChanged;
  final SoilKind? soil;
  final ValueChanged<SoilKind?> onSoilChanged;
  final TextEditingController careNotesController;
  final TextEditingController originController;
  final List<Room> rooms;
  final String? roomId;
  final ValueChanged<String?> onRoomChanged;
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
    required this.lighting,
    required this.onLightingChanged,
    required this.watering,
    required this.onWateringChanged,
    required this.soil,
    required this.onSoilChanged,
    required this.careNotesController,
    required this.originController,
    this.rooms = const [],
    this.roomId,
    required this.onRoomChanged,
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
        if (rooms.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          _CareDropdown<String>(
            label: 'Room',
            labelStyle: labelStyle,
            value: rooms.any((r) => r.id == roomId) ? roomId : null,
            values: [for (final room in rooms) room.id],
            display: (id) => rooms.firstWhere((r) => r.id == id).name,
            onChanged: onRoomChanged,
          ),
        ],
        SizedBox(height: spacing.xl),
        Text(
          'Care',
          style: textTheme.displaySmall?.copyWith(fontSize: 22),
        ),
        SizedBox(height: spacing.sm),
        _FieldRow(
          left: _CareDropdown<LightingLevel>(
            label: 'Preferred lighting',
            labelStyle: labelStyle,
            value: lighting,
            values: LightingLevel.values,
            display: (v) => v.label,
            onChanged: onLightingChanged,
          ),
          right: _CareDropdown<WateringLevel>(
            label: 'Watering level',
            labelStyle: labelStyle,
            value: watering,
            values: WateringLevel.values,
            display: (v) => v.label,
            onChanged: onWateringChanged,
          ),
        ),
        SizedBox(height: spacing.sm),
        _FieldRow(
          left: _CareDropdown<SoilKind>(
            label: 'Soil type',
            labelStyle: labelStyle,
            value: soil,
            values: SoilKind.values,
            display: (v) => v.label,
            onChanged: onSoilChanged,
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
        SizedBox(height: spacing.sm),
        TextField(
          controller: careNotesController,
          decoration: InputDecoration(
            labelText: 'Care notes',
            hintText: 'Anything special about caring for this plant',
            labelStyle: labelStyle,
          ),
          maxLines: 3,
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

/// Nullable dropdown for the structured care vocabularies; the null item
/// reads "Not set" so every field stays optional.
class _CareDropdown<T> extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;
  final T? value;
  final List<T> values;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;

  const _CareDropdown({
    required this.label,
    required this.labelStyle,
    required this.value,
    required this.values,
    required this.display,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
      ),
      items: [
        DropdownMenuItem<T?>(value: null, child: const Text('Not set')),
        for (final item in values)
          DropdownMenuItem<T?>(value: item, child: Text(display(item))),
      ],
      onChanged: onChanged,
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
