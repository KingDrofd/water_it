import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_detail_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_form_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_form_content.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_form_header.dart';
import 'package:water_it/features/plants/presentation/widgets/reminder_widgets.dart';
import 'package:water_it/features/plants/presentation/utils/plant_form_handlers.dart';

class PlantEditPage extends StatefulWidget {
  final String plantId;

  const PlantEditPage({
    super.key,
    required this.plantId,
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
  final List<ReminderDraft> _reminders = [];
  final List<String> _imagePaths = [];
  bool _useRandomImage = false;
  static const int _maxImages = 4;
  final PlantImageHandler _imageHandler =
      PlantImageHandler(maxImages: _maxImages);
  final ReminderHandlers _reminderHandlers = ReminderHandlers();
  Plant? _plant;
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

  void _applyPlant(Plant plant) {
    setState(() {
      _plant = plant;
      _nameController.text = plant.name;
      _scientificController.text = plant.scientificName ?? '';
      _descriptionController.text = plant.description ?? '';
      _lightingController.text = plant.preferredLighting ?? '';
      _soilController.text = plant.soilType ?? '';
      _wateringController.text = plant.wateringLevel ?? '';
      _originController.text = plant.origin ?? '';
      _ageController.text = plant.ageMonths?.toString() ?? '';
      for (final reminder in _reminders) {
        reminder.dispose();
      }
      _reminders
        ..clear()
        ..addAll(
          plant.reminders
              .map(
                (reminder) => ReminderDraft.fromReminder(reminder),
              )
              .toList(),
        );
      if (_reminders.isEmpty) {
        _reminders.add(ReminderDraft.empty());
      }
      _imagePaths
        ..clear()
        ..addAll(plant.imagePaths);
      _useRandomImage = plant.useRandomImage;
    });
  }
  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelLarge?.copyWith(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PlantDetailCubit(getIt())..loadPlant(widget.plantId),
        ),
        BlocProvider(
          create: (_) => PlantFormCubit(getIt()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<PlantDetailCubit, PlantDetailState>(
            listenWhen: (previous, current) =>
                previous.plant != current.plant &&
                current.status == PlantDetailStatus.loaded,
            listener: (context, state) {
              final plant = state.plant;
              if (plant != null) {
                _applyPlant(plant);
              }
            },
          ),
          BlocListener<PlantFormCubit, PlantFormState>(
            listener: (context, state) {
              if (state.status == PlantFormStatus.success) {
                getIt<PlantListCubit>().loadPlants();
                Navigator.of(context).pop(true);
              } else if (state.status == PlantFormStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.errorMessage ?? 'Unable to save changes.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                PlantFormHeader(
                  title: 'Edit Plant',
                  onBack: () => Navigator.of(context).pop(),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.lg,
                    spacing.sm,
                    spacing.lg,
                    spacing.lg,
                  ),
                  sliver: BlocBuilder<PlantDetailCubit, PlantDetailState>(
                    builder: (context, state) {
                      if (state.status == PlantDetailStatus.loading) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (state.status == PlantDetailStatus.failure) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              state.errorMessage ?? 'Unable to load plant.',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        );
                      }
                      if (state.status == PlantDetailStatus.notFound) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'Plant not found.',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        );
                      }

                      return SliverToBoxAdapter(
                        child: PlantFormContent(
                          imageLabel: 'Edit images',
                          imagePaths: _imagePaths,
                          useRandomImage: _useRandomImage,
                          onAddImage: _pickImages,
                          onRemoveImage: _removeImage,
                          onSelectPrimary: _setPrimaryImage,
                          onRandomChanged: (value) {
                            setState(() {
                              _useRandomImage = value;
                            });
                          },
                          nameController: _nameController,
                          scientificController: _scientificController,
                          ageController: _ageController,
                          descriptionController: _descriptionController,
                          lightingController: _lightingController,
                          wateringController: _wateringController,
                          soilController: _soilController,
                          originController: _originController,
                          labelStyle: labelStyle,
                          reminderInputs: _buildReminderInputs(),
                          onAddReminder: () => setState(() {
                            _reminderHandlers.addReminder(
                              reminders: _reminders,
                              onChanged: () {},
                            );
                          }),
                          saveButton: BlocBuilder<PlantFormCubit, PlantFormState>(
                            builder: (context, formState) {
                              return AppPrimaryButton(
                                onPressed: formState.status ==
                                        PlantFormStatus.saving
                                    ? null
                                    : () => _save(context),
                                label: formState.status ==
                                        PlantFormStatus.saving
                                    ? 'Saving...'
                                    : 'Save Changes',
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
    final existing = _plant ??
        Plant(
          id: widget.plantId,
          name: trimmedName,
        );
    final reminderItems = _buildRemindersForSave(context, existing.id);
    if (reminderItems == null) {
      return;
    }
    final updated = existing.copyWith(
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

    context.read<PlantFormCubit>().savePlant(updated);
  }

  String? _nullable(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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
              onPickTime: () => _reminderHandlers.pickTime(
                context: context,
                reminder: reminder,
                onChanged: () => setState(() {}),
              ),
              onClearTime: () => _reminderHandlers.clearTime(
                reminder: reminder,
                onChanged: () => setState(() {}),
              ),
              onToggleDay: (day) => _reminderHandlers.toggleDay(
                reminder: reminder,
                day: day,
                onChanged: () => setState(() {}),
              ),
              onRemove: _reminders.length > 1
                  ? () {
                      setState(() {
                        _reminderHandlers.removeReminder(
                          reminders: _reminders,
                          reminder: reminder,
                          onChanged: () {},
                        );
                      });
                    }
                  : null,
            ),
          ),
        )
        .toList();
  }

  Future<void> _pickImages() async {
    await _imageHandler.pickImages(
      imagePaths: _imagePaths,
      onLimitReached: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Max 4 images per plant.')),
        );
      },
      onLimitExceeded: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only 4 images are allowed.')),
        );
      },
      onChanged: () => setState(() {}),
    );
  }

  void _removeImage(String path) {
    setState(() {
      _imageHandler.removeImage(
        imagePaths: _imagePaths,
        path: path,
        onChanged: () {},
      );
    });
  }

  void _setPrimaryImage(String path) {
    setState(() {
      _imageHandler.setPrimaryImage(
        imagePaths: _imagePaths,
        path: path,
        onChanged: () {},
      );
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

