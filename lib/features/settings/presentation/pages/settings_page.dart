import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/sliver_page_header.dart';
import 'package:water_it/features/home/presentation/utils/home_location_controller.dart';
import 'package:water_it/features/settings/presentation/widgets/settings_sections.dart';
import 'package:water_it/features/plants/domain/usecases/get_plants.dart';

enum SettingsSection {
  notifications,
  weather,
  about,
}

const bool _enableNotificationDebug = bool.fromEnvironment(
  'ENABLE_NOTIFICATION_DEBUG',
  defaultValue: false,
);

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

  Future<void> _updateWateringReminders(bool value) async {
    setState(() {
      _wateringReminders = value;
    });
    await AppSettings.setWateringRemindersEnabled(value);

    try {
      final service = getIt<NotificationService>();
      if (value) {
        final granted = await service.requestPermissions();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications permission not granted.'),
              ),
            );
          }
          return;
        }
        final plants = await getIt<GetPlants>()();
        await service.scheduleWateringReminders(plants);
      } else {
        await service.cancelAll();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifications error: $error')),
        );
      }
    }

  }

  Future<void> _sendTestNotification(BuildContext context) async {
    try {
      final service = getIt<NotificationService>();
      final granted = await service.requestPermissions();
      if (!granted) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications permission not granted.')),
        );
        return;
      }
      await service.cancelAll();
      final exact = await service.showTestNotification(
        delay: const Duration(seconds: 10),
      );
      final pendingCount = await service.pendingCount();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exact
                ? 'Test scheduled. Pending: $pendingCount.'
                : 'Exact alarms not permitted; pending: $pendingCount.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test notification failed: $error')),
      );
    }
  }

  Future<void> _sendImmediateTest(BuildContext context) async {
    try {
      final service = getIt<NotificationService>();
      final granted = await service.requestPermissions();
      if (!granted) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications permission not granted.')),
        );
        return;
      }
      await service.showImmediateTestNotification();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Immediate test sent.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Immediate test failed: $error')),
      );
    }
  }

  Future<void> _openAppSettings(BuildContext context) async {
    final opened = await openAppSettings();
    if (!mounted) {
      return;
    }
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open app settings.')),
      );
    }
  }

  Future<void> _requestExactAlarmsPermission(BuildContext context) async {
    final service = getIt<NotificationService>();
    final granted = await service.requestExactAlarmsPermission();
    if (!mounted) {
      return;
    }
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exact alarms permission granted.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exact alarms permission not granted.'),
      ),
    );
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
                                    subtitle:
                                        'Get reminders on your chosen days and time.\nTimes follow your device time zone.',
                                    value: _wateringReminders,
                                    isLoading: _isLoading,
                                    onChanged: _updateWateringReminders,
                                  ),
                                  SettingsSwitchTile(
                                    title: 'Daily summary',
                                    subtitle: 'A short recap delivered each morning.',
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
                                  if (_enableNotificationDebug && kDebugMode)
                                    SettingsTile(
                                      title: 'Send scheduled test notification',
                                      subtitle: 'Schedules a notification in 10s.',
                                      onTap: _isLoading
                                          ? null
                                          : () => _sendTestNotification(context),
                                    ),
                                  if (_enableNotificationDebug && kDebugMode)
                                    SettingsTile(
                                      title: 'Send immediate test notification',
                                      subtitle: 'Fires a notification right now.',
                                      onTap: _isLoading
                                          ? null
                                          : () => _sendImmediateTest(context),
                                    ),
                                  if (_enableNotificationDebug && kDebugMode)
                                    SettingsTile(
                                      title: 'Open app settings',
                                      subtitle: 'Enable Alarms & reminders permission.',
                                      onTap: _isLoading
                                          ? null
                                          : () => _openAppSettings(context),
                                    ),
                                  if (_enableNotificationDebug && kDebugMode)
                                    SettingsTile(
                                      title: 'Request exact alarms permission',
                                      subtitle: 'Ask Android for exact scheduling.',
                                      onTap: _isLoading
                                          ? null
                                          : () =>
                                              _requestExactAlarmsPermission(context),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: spacing.sm),
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
                            SizedBox(height: spacing.sm),
                            KeyedSubtree(
                              key: _sectionKeys[SettingsSection.about],
                              child: SettingsSectionCard(
                                title: 'About',
                                children: [
                                  const SettingsTile(
                                    title: 'App version',
                                    subtitle: 'Build 0.1.0',
                                  ),
                                  SettingsTile(
                                    title: 'Licenses',
                                    subtitle: 'View open source attributions.',
                                    onTap: () => showLicensePage(
                                      context: context,
                                      applicationName: 'Water It',
                                      applicationVersion: '0.1.0',
                                    ),
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
