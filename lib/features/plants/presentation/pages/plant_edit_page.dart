import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';

class PlantEditPage extends StatefulWidget {
  final String name;

  const PlantEditPage({
    super.key,
    required this.name,
  });

  @override
  State<PlantEditPage> createState() => _PlantEditPageState();
}

class _PlantEditPageState extends State<PlantEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _scientificController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _lightingController;
  late final TextEditingController _soilController;
  late final TextEditingController _wateringController;
  late final TextEditingController _originController;
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _scientificController = TextEditingController(text: 'Epipremnum aureum');
    _descriptionController = TextEditingController(
      text: 'Rotate weekly for even growth. Avoid direct sun.',
    );
    _lightingController = TextEditingController(text: 'Bright indirect');
    _soilController = TextEditingController(text: 'Loamy soil');
    _wateringController = TextEditingController(text: 'Moderate');
    _originController = TextEditingController(text: 'French Polynesia');
    _ageController = TextEditingController(text: '2 years');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    _descriptionController.dispose();
    _lightingController.dispose();
    _soilController.dispose();
    _wateringController.dispose();
    _originController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppBarIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                    size: 48,
                    radius: 12,
                  ),
                  SizedBox(width: spacing.md),
                  Text('Edit Plant', style: textTheme.headlineSmall),
                ],
              ),
              SizedBox(height: spacing.lg),
              Expanded(
                child: ListView(
                  children: [
                    _ImagePickerCard(),
                    SizedBox(height: spacing.lg),
                    Text('Basics', style: textTheme.titleMedium),
                    SizedBox(height: spacing.sm),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Golden pothos',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    TextField(
                      controller: _scientificController,
                      decoration: const InputDecoration(
                        labelText: 'Scientific name',
                        hintText: 'Epipremnum aureum',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional notes about this plant',
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: spacing.lg),
                    Text('Care', style: textTheme.titleMedium),
                    SizedBox(height: spacing.sm),
                    TextField(
                      controller: _lightingController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred lighting',
                        hintText: 'Bright indirect',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    TextField(
                      controller: _soilController,
                      decoration: const InputDecoration(
                        labelText: 'Soil type',
                        hintText: 'Loamy soil',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    TextField(
                      controller: _wateringController,
                      decoration: const InputDecoration(
                        labelText: 'Watering level',
                        hintText: 'Moderate',
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    Text('Metadata', style: textTheme.titleMedium),
                    SizedBox(height: spacing.sm),
                    TextField(
                      controller: _originController,
                      decoration: const InputDecoration(
                        labelText: 'Origin',
                        hintText: 'French Polynesia',
                      ),
                    ),
                    SizedBox(height: spacing.sm),
                    TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        hintText: '2 years',
                      ),
                    ),
                    SizedBox(height: spacing.lg),
                    Text('Reminders', style: textTheme.titleMedium),
                    SizedBox(height: spacing.sm),
                    _ReminderRow(label: 'Water every', value: '7 days'),
                    SizedBox(height: spacing.sm),
                    _ReminderRow(label: 'Fertilize every', value: '30 days'),
                    SizedBox(height: spacing.lg),
                    AppPrimaryButton(
                      onPressed: () {},
                      label: 'Save Changes',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: colorScheme.primary),
            SizedBox(height: spacing.sm),
            Text('Edit images', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReminderRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: textTheme.bodyMedium),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Text(value, style: textTheme.labelMedium),
        ),
      ],
    );
  }
}
