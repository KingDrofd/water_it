import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/sliver_page_header.dart';
import 'package:water_it/features/home/presentation/utils/home_location_controller.dart';
import 'package:water_it/features/settings/presentation/widgets/settings_sections.dart';

enum SettingsSection {
  notifications,
  weather,
  about,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.initialSection,
  });

  final SettingsSection? initialSection;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  late final Map<SettingsSection, GlobalKey> _sectionKeys = {
    SettingsSection.notifications: GlobalKey(),
    SettingsSection.weather: GlobalKey(),
    SettingsSection.about: GlobalKey(),
  };
  bool _wateringReminders = true;
  bool _dailySummary = false;
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;
  bool _isLoading = true;
  String _locationLabel = 'Set your location';
  String _locationNote = 'Tap to choose';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final section = widget.initialSection;
      if (section != null) {
        _scrollToSection(section);
      }
    });
  }

  Future<void> _loadSettings() async {
    final unit = await AppSettings.getTemperatureUnit();
    final watering = await AppSettings.getWateringRemindersEnabled();
    final summary = await AppSettings.getDailySummaryEnabled();
    final location = await readLocationPreference();
    if (!mounted) {
      return;
    }
    setState(() {
      _temperatureUnit = unit;
      _wateringReminders = watering;
      _dailySummary = summary;
      _locationLabel = location.label;
      _locationNote = location.note;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(SettingsSection section) {
    final targetContext = _sectionKeys[section]?.currentContext;
    if (targetContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _selectLocation(BuildContext context) async {
    final controller = HomeLocationController(
      loadWeather: (_, __) async {},
      setState: (_) {},
      showError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );

    await controller.promptForLocation(context);
    controller.dispose();
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = AppLayout.pagePadding(width);
          final contentMax = AppLayout.maxContentWidth(width);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: SafeArea(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPageHeader(
                      title: 'Settings',
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        spacing.sm,
                        padding.right,
                        padding.bottom,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            KeyedSubtree(
                              key: _sectionKeys[SettingsSection.notifications],
                              child: SettingsSectionCard(
                                title: 'Notifications',
                                children: [
                                  SettingsSwitchTile(
                                    title: 'Watering reminders',
                                    subtitle: 'Manage reminder schedule.',
                                    value: _wateringReminders,
                                    isLoading: _isLoading,
                                    onChanged: (value) async {
                                      setState(() {
                                        _wateringReminders = value;
                                      });
                                      await AppSettings
                                          .setWateringRemindersEnabled(value);
                                    },
                                  ),
                                  SettingsSwitchTile(
                                    title: 'Daily summary',
                                    subtitle: 'Get a quick morning snapshot.',
                                    value: _dailySummary,
                                    isLoading: _isLoading,
                                    onChanged: (value) async {
                                      setState(() {
                                        _dailySummary = value;
                                      });
                                      await AppSettings
                                          .setDailySummaryEnabled(value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: spacing.md),
                            KeyedSubtree(
                              key: _sectionKeys[SettingsSection.weather],
                              child: SettingsSectionCard(
                                title: 'Weather',
                                children: [
                                  SettingsTile(
                                    title: 'Location',
                                    subtitle: '$_locationLabel - $_locationNote',
                                    onTap: _isLoading
                                        ? null
                                        : () => _selectLocation(context),
                                  ),
                                  SettingsUnitsTile(
                                    unit: _temperatureUnit,
                                    isLoading: _isLoading,
                                    onChanged: (unit) async {
                                      setState(() {
                                        _temperatureUnit = unit;
                                      });
                                      await AppSettings.setTemperatureUnit(unit);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: spacing.md),
                            KeyedSubtree(
                              key: _sectionKeys[SettingsSection.about],
                              child: SettingsSectionCard(
                                title: 'About',
                                children: const [
                                  SettingsTile(
                                    title: 'App version',
                                    subtitle: 'Build 0.1.0',
                                  ),
                                  SettingsTile(
                                    title: 'Licenses',
                                    subtitle: 'View open source attributions.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
