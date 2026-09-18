import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/buttons/app_primary_button.dart';
import 'package:water_it/features/plants/domain/entities/care_profile.dart';
import 'package:water_it/features/plants/domain/entities/plant.dart';
import 'package:water_it/features/plants/domain/entities/room.dart';
import 'package:water_it/features/plants/domain/usecases/get_rooms.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_form_cubit.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/widgets/plant_form_content.dart';
import 'package:water_it/core/widgets/app_bars/sliver_page_header.dart';
import 'package:water_it/features/plants/presentation/widgets/reminder_widgets.dart';
import 'package:water_it/features/plants/presentation/utils/plant_form_handlers.dart';

class PlantFormPage extends StatefulWidget {
  const PlantFormPage({
    super.key,
    this.initialImagePaths = const [],
  });

  final List<String> initialImagePaths;

  @override
  State<PlantFormPage> createState() => _PlantFormPageState();
}

class _PlantFormPageState extends State<PlantFormPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _scientificController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _careNotesController;
  late final TextEditingController _originController;
  late final TextEditingController _ageController;
  LightingLevel? _lighting;
  WateringLevel? _watering;
  SoilKind? _soil;
  String? _roomId;
  List<Room> _rooms = const [];
  final List<ReminderDraft> _reminders = [];
  final List<String> _imagePaths = [];
  bool _useRandomImage = false;
  bool _showReminderWeekdayError = false;
  static const int _maxImages = 4;
  final PlantImageHandler _imageHandler =
      PlantImageHandler(maxImages: _maxImages);
  final ReminderHandlers _reminderHandlers = ReminderHandlers();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _scientificController = TextEditingController();
    _descriptionController = TextEditingController();
    _careNotesController = TextEditingController();
    _originController = TextEditingController();
    _ageController = TextEditingController();
    _reminders.add(ReminderDraft.empty());
    _imagePaths.addAll(widget.initialImagePaths);
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await getIt<GetRooms>()();
    if (mounted) {
      setState(() {
        _rooms = rooms;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificController.dispose();
    _descriptionController.dispose();
    _careNotesController.dispose();
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
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = textTheme.labelLarge?.copyWith(
      fontFamily: 'Quicksand',
      fontWeight: FontWeight.w600,
    );

    return BlocProvider(
      create: (_) => PlantFormCubit(getIt()),
      child: BlocListener<PlantFormCubit, PlantFormState>(
        listener: (context, state) async {
          if (state.status == PlantFormStatus.success) {
            await getIt<PlantListCubit>().loadPlants();
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
            child: CustomScrollView(
              slivers: [
                SliverPageHeader(
                  title: 'Add Plant',
                  onBack: () => Navigator.of(context).pop(),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.lg,
                    spacing.sm,
                    spacing.lg,
                    spacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: PlantFormContent(
                      imageLabel: 'Add images',
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
                      lighting: _lighting,
                      onLightingChanged: (value) =>
                          setState(() => _lighting = value),
                      watering: _watering,
                      onWateringChanged: (value) =>
                          setState(() => _watering = value),
                      soil: _soil,
                      onSoilChanged: (value) => setState(() => _soil = value),
                      careNotesController: _careNotesController,
                      originController: _originController,
                      rooms: _rooms,
                      roomId: _roomId,
                      onRoomChanged: (value) =>
                          setState(() => _roomId = value),
                      labelStyle: labelStyle,
                      reminderInputs: [
                        ReminderInputList(
                          reminders: _reminders,
                          handlers: _reminderHandlers,
                          onChanged: () => setState(() {
                            _showReminderWeekdayError = false;
                          }),
                        ),
                        if (_showReminderWeekdayError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Select at least one weekday for reminders.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                      onAddReminder: () => setState(() {
                        _reminderHandlers.addReminder(
                          reminders: _reminders,
                          onChanged: () {},
                        );
                        _showReminderWeekdayError = false;
                      }),
                      saveButton: BlocBuilder<PlantFormCubit, PlantFormState>(
                        builder: (context, state) {
                          return AppPrimaryButton(
                            onPressed: state.status == PlantFormStatus.saving
                                ? null
                                : () => _save(context),
                            label: state.status == PlantFormStatus.saving
                                ? 'Saving...'
                                : 'Save Plant',
                          );
                        },
                      ),
                    ),
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
      preferredLighting: _lighting,
      soilType: _soil,
      wateringLevel: _watering,
      careNotes: _nullable(_careNotesController),
      origin: _nullable(_originController),
      roomId: _roomId,
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
        setState(() {
          _showReminderWeekdayError = true;
        });
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
          // New reminders are stamped now so they don't inherit this week's
          // earlier due moment as an instant "overdue".
          createdAt: reminder.createdAt ?? DateTime.now(),
        ),
      );
    }
    return reminders;
  }
}
