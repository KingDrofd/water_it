import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/app_bar_icon_button.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_form_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_image_picker.dart';
import 'package:water_it/features/plants/presentation/widgets/reminder_widgets.dart';

class PlantFormPage extends StatefulWidget {
  const PlantFormPage({
    super.key,
    this.initialImagePath,
  });

  final String? initialImagePath;

  @override
  State<PlantFormPage> createState() => _PlantFormPageState();
}

class _PlantFormPageState extends State<PlantFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _scientificController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _lightingController;
  late final TextEditingController _soilController;
  late final TextEditingController _wateringController;
  late final TextEditingController _originController;
  late final TextEditingController _ageController;
  final List<ReminderDraft> _reminders = [];
  final List<String> _imagePaths = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _useRandomImage = false;
  static const int _maxImages = 4;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _scientificController = TextEditingController();
    _descriptionController = TextEditingController();
    _lightingController = TextEditingController();
    _soilController = TextEditingController();
    _wateringController = TextEditingController();
    _originController = TextEditingController();
    _ageController = TextEditingController();
    _reminders.add(ReminderDraft.empty());
    if (widget.initialImagePath != null &&
        widget.initialImagePath!.isNotEmpty) {
      _imagePaths.add(widget.initialImagePath!);
    }
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
    for (final reminder in _reminders) {
      reminder.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider(
      create: (_) => PlantFormCubit(getIt()),
      child: BlocListener<PlantFormCubit, PlantFormState>(
        listener: (context, state) {
          if (state.status == PlantFormStatus.success) {
            getIt<PlantListCubit>().loadPlants();
            Navigator.of(context).pop(true);
          } else if (state.status == PlantFormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? 'Unable to save plant.',
                ),
              ),
            );
          }
        },
        child: Scaffold(
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
                      Text('Add Plant', style: textTheme.headlineSmall),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  Expanded(
                    child: ListView(
                      children: [
                        PlantImagePickerCard(
                          imagePaths: _imagePaths,
                          onAdd: _pickImages,
                          onRemove: _removeImage,
                          onSelectPrimary: _setPrimaryImage,
                          useRandomImage: _useRandomImage,
                          onRandomChanged: (value) {
                            setState(() {
                              _useRandomImage = value;
                            });
                          },
                          label: 'Add images',
                        ),
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
                        _buildFieldRow(
                          context,
                          TextField(
                            controller: _scientificController,
                            decoration: const InputDecoration(
                              labelText: 'Scientific name',
                              hintText: 'Epipremnum aureum',
                            ),
                          ),
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Age (months)',
                              hintText: '24',
                            ),
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
                        _buildFieldRow(
                          context,
                          TextField(
                            controller: _lightingController,
                            decoration: const InputDecoration(
                              labelText: 'Preferred lighting',
                              hintText: 'Bright indirect',
                            ),
                          ),
                          TextField(
                            controller: _wateringController,
                            decoration: const InputDecoration(
                              labelText: 'Watering level',
                              hintText: 'Moderate',
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        _buildFieldRow(
                          context,
                          TextField(
                            controller: _soilController,
                            decoration: const InputDecoration(
                              labelText: 'Soil type',
                              hintText: 'Loamy soil',
                            ),
                          ),
                          TextField(
                            controller: _originController,
                            decoration: const InputDecoration(
                              labelText: 'Origin',
                              hintText: 'French Polynesia',
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.lg),
                        Text('Reminders', style: textTheme.titleMedium),
                        SizedBox(height: spacing.sm),
                        ..._buildReminderInputs(),
                        TextButton.icon(
                          onPressed: _addReminder,
                          icon: const Icon(Icons.add),
                          label: const Text('Add reminder'),
                        ),
                        SizedBox(height: spacing.lg),
                        BlocBuilder<PlantFormCubit, PlantFormState>(
                          builder: (context, state) {
                            return AppPrimaryButton(
                              onPressed:
                                  state.status == PlantFormStatus.saving
                                      ? null
                                      : () => _save(context),
                              label: state.status == PlantFormStatus.saving
                                  ? 'Saving...'
                                  : 'Save Plant',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required.')),
      );
      return;
    }

    final ageMonths = int.tryParse(_ageController.text.trim());
    final plantId = const Uuid().v4();
    final reminderItems = _buildRemindersForSave(context, plantId);
    if (reminderItems == null) {
      return;
    }
    final plant = Plant(
      id: plantId,
      name: trimmedName,
      scientificName: _nullable(_scientificController),
      description: _nullable(_descriptionController),
      preferredLighting: _nullable(_lightingController),
      soilType: _nullable(_soilController),
      wateringLevel: _nullable(_wateringController),
      origin: _nullable(_originController),
      ageMonths: ageMonths,
      imagePaths: List<String>.from(_imagePaths),
      useRandomImage: _useRandomImage,
      reminders: reminderItems,
    );

    context.read<PlantFormCubit>().savePlant(plant);
  }

  String? _nullable(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Widget _buildFieldRow(BuildContext context, Widget left, Widget right) {
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

  List<Widget> _buildReminderInputs() {
    if (_reminders.isEmpty) {
      return [
        Text(
          'No reminders yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ];
    }

    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return _reminders
        .map(
          (reminder) => Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: ReminderInputRow(
              reminder: reminder,
              onPickTime: () => _pickReminderDateTime(reminder),
              onClearTime: () => _clearReminderDateTime(reminder),
              onToggleDay: (day) => _toggleReminderDay(reminder, day),
              onRemove: _reminders.length > 1
                  ? () {
                      setState(() {
                        reminder.dispose();
                        _reminders.remove(reminder);
                      });
                    }
                  : null,
            ),
          ),
        )
        .toList();
  }

  void _addReminder() {
    setState(() {
      _reminders.add(ReminderDraft.empty());
    });
  }

  void _toggleReminderDay(ReminderDraft reminder, int day) {
    setState(() {
      if (reminder.weekdays.contains(day)) {
        reminder.weekdays.remove(day);
      } else {
        reminder.weekdays.add(day);
      }
    });
  }

  Future<void> _pickReminderDateTime(ReminderDraft reminder) async {
    final now = DateTime.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(reminder.preferredTime ?? now),
    );
    if (pickedTime == null) {
      return;
    }
    setState(() {
      reminder.preferredTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _clearReminderDateTime(ReminderDraft reminder) {
    setState(() {
      reminder.preferredTime = null;
    });
  }

  Future<void> _pickImages() async {
    if (_imagePaths.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 4 images per plant.')),
      );
      return;
    }
    final images = await _imagePicker.pickMultiImage();
    if (images.isEmpty) {
      return;
    }
    final remaining = _maxImages - _imagePaths.length;
    final selected = images.take(remaining);
    setState(() {
      _imagePaths.addAll(selected.map((image) => image.path));
    });
    if (images.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only 4 images are allowed.')),
      );
    }
  }

  void _removeImage(String path) {
    setState(() {
      _imagePaths.remove(path);
    });
  }

  void _setPrimaryImage(String path) {
    final index = _imagePaths.indexOf(path);
    if (index <= 0) {
      return;
    }
    setState(() {
      _imagePaths
        ..removeAt(index)
        ..insert(0, path);
    });
  }

  List<WateringReminder>? _buildRemindersForSave(
    BuildContext context,
    String plantId,
  ) {
    final reminders = <WateringReminder>[];
    for (final reminder in _reminders) {
      final notesText = reminder.notesController.text.trim();
      if (reminder.weekdays.isEmpty && notesText.isEmpty) {
        continue;
      }
      if (reminder.weekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select at least one weekday for reminders.'),
          ),
        );
        return null;
      }
      reminders.add(
        WateringReminder(
          id: reminder.id,
          plantId: plantId,
          frequencyDays: 7,
          weekdays: reminder.weekdays.toList()..sort(),
          preferredTime: reminder.preferredTime,
          notes: notesText.isEmpty ? null : notesText,
        ),
      );
    }
    return reminders;
  }
}
