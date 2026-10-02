import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:water_it/features/backup/data/backup_service.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:water_it/core/app_info/app_info.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/notifications/reminder_permission_flow.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/sliver_page_header.dart';
import 'package:water_it/features/home/presentation/utils/home_location_controller.dart';
import 'package:water_it/features/feedback/presentation/pages/feedback_page.dart';
import 'package:water_it/features/settings/presentation/widgets/settings_sections.dart';
import 'package:water_it/features/plants/domain/services/reminder_scheduler.dart';

enum SettingsSection {
  notifications,
  weather,
  data,
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

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late final Map<SettingsSection, GlobalKey> _sectionKeys = {
    SettingsSection.notifications: GlobalKey(),
    SettingsSection.weather: GlobalKey(),
    SettingsSection.data: GlobalKey(),
    SettingsSection.about: GlobalKey(),
  };
  bool _backupBusy = false;
  NotificationReadiness? _readiness;
  String? _displayName;
  bool _wateringReminders = true;
  bool _dailySummary = false;
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;
  bool _isLoading = true;
  String _locationLabel = 'Set your location';
  String _locationNote = 'Tap to choose';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadAppVersion();
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
    await _loadReadiness();
    final name = await AppSettings.getDisplayName();
    if (mounted) {
      setState(() => _displayName = name);
    }
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Shown in the Home greeting',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) {
      return; // Cancelled.
    }
    await AppSettings.setDisplayName(result);
    if (mounted) {
      setState(() => _displayName = AppSettings.displayNameNotifier.value);
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() {
      _appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reflect a permission the user may have just toggled in system settings.
      _loadReadiness();
    }
  }

  Future<void> _loadReadiness() async {
    try {
      final readiness = await getIt<NotificationService>().readiness();
      if (mounted) {
        setState(() => _readiness = readiness);
      }
    } catch (_) {
      // Status row simply stays on its last known value.
    }
  }

  Future<void> _fixReminderDelivery() async {
    final readiness = _readiness;
    if (readiness == null) {
      return;
    }
    if (readiness.blocked) {
      await getIt<NotificationService>().requestPermissions();
    } else if (readiness.batteryRestricted) {
      await ReminderPermissionFlow.requestBatteryExemption(context);
    } else {
      await ReminderPermissionFlow.requestExactAlarms(context);
    }
    await _loadReadiness();
  }

  /// Plain-language summary of whether reminders will actually arrive, and
  /// on time. Android's two grants are collapsed into one honest line.
  String get _deliverySubtitle {
    final readiness = _readiness;
    if (readiness == null) {
      return 'Checking...';
    }
    if (!readiness.remindersEnabled) {
      return 'Turn on watering reminders to use this.';
    }
    if (readiness.blocked) {
      return 'Blocked by Android - notifications are switched off. Tap to fix.';
    }
    if (readiness.batteryRestricted) {
      return 'Battery saving may stop reminders arriving. Tap to allow them through.';
    }
    if (readiness.imprecise) {
      return ReminderPermissionFlow.exactAlarmPromptsEnabled
          ? 'Reminders may arrive hours late. Tap to allow precise timing.'
          : 'Reminders arrive, but Android decides their exact timing.';
    }
    return 'Reminders arrive at the time you set.';
  }

  bool get _deliveryNeedsAttention {
    final readiness = _readiness;
    if (readiness == null) {
      return false;
    }
    return readiness.blocked ||
        readiness.batteryRestricted ||
        (ReminderPermissionFlow.exactAlarmPromptsEnabled &&
            readiness.imprecise);
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
      loadWeather: (_, _) async {},
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
        if (mounted) {
          await ReminderPermissionFlow.requestExactAlarms(context);
        }
        await getIt<ReminderScheduler>().rescheduleAll();
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
    await _loadReadiness();
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


  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _exportData() async {
    setState(() => _backupBusy = true);
    try {
      final bytes = await getIt<BackupService>().exportArchive();
      final now = DateTime.now();
      final stamp = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Water It backup',
        fileName: 'water_it_backup_$stamp.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: bytes,
      );
      if (path == null) {
        return; // User cancelled.
      }
      // On desktop, saveFile only returns the location — write it ourselves.
      if (!Platform.isAndroid && !Platform.isIOS) {
        await File(path).writeAsBytes(bytes);
      }
      _showMessage('Backup exported.');
    } catch (error) {
      _showMessage('Export failed: $error');
    } finally {
      if (mounted) {
        setState(() => _backupBusy = false);
      }
    }
  }

  Future<void> _importData() async {
    setState(() => _backupBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Pick a Water It backup',
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return; // User cancelled.
      }
      final file = result.files.first;
      final bytes = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) {
        _showMessage('Could not read the selected file.');
        return;
      }

      final summary = BackupService.readSummary(bytes);
      if (summary == null) {
        _showMessage('Not a Water It backup file.');
        return;
      }
      if (!mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace all data?'),
          content: Text(
            'This backup contains ${summary.plantCount} plants, '
            '${summary.roomCount} rooms, ${summary.careTaskCount} care tasks, '
            '${summary.careEventCount} care events, and '
            '${summary.imageCount} photos.\n\n'
            'Importing replaces everything currently in the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }

      await getIt<BackupService>().importArchive(bytes);
      await AppSettings.syncTemperatureUnit();
      await getIt<PlantListCubit>().loadPlants();
      await _loadSettings();
      _showMessage('Backup imported.');
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Import failed: $error');
    } finally {
      if (mounted) {
        setState(() => _backupBusy = false);
      }
    }
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
                            SettingsSectionCard(
                              title: 'You',
                              children: [
                                SettingsTile(
                                  title: 'Your name',
                                  subtitle: _displayName == null
                                      ? 'Optional - personalises the Home greeting. Stays on this phone.'
                                      : _displayName!,
                                  onTap: _isLoading ? null : _editDisplayName,
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.sm),
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
                                      try {
                                        await getIt<ReminderScheduler>()
                                            .rescheduleAll();
                                      } catch (_) {
                                        // Summary picks up on next reschedule.
                                      }
                                    },
                                  ),
                                  SettingsTile(
                                    title: _deliveryNeedsAttention
                                        ? 'Reminder delivery - action needed'
                                        : 'Reminder delivery',
                                    subtitle: _deliverySubtitle,
                                    onTap: _isLoading || !_deliveryNeedsAttention
                                        ? null
                                        : _fixReminderDelivery,
                                  ),
                                  SettingsTile(
                                    title: 'Reminders not arriving?',
                                    subtitle:
                                        'Extra steps for Samsung, Xiaomi and other phone makers.',
                                    onTap: () =>
                                        ReminderPermissionFlow
                                            .showManufacturerHelp(context),
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
                              key: _sectionKeys[SettingsSection.data],
                              child: SettingsSectionCard(
                                title: 'Data',
                                children: [
                                  SettingsTile(
                                    title: 'Export data',
                                    subtitle:
                                        'Save plants, photos, and care history as a zip file.',
                                    onTap: _isLoading || _backupBusy
                                        ? null
                                        : _exportData,
                                  ),
                                  SettingsTile(
                                    title: 'Import data',
                                    subtitle:
                                        'Restore from a backup zip. Replaces current data.',
                                    onTap: _isLoading || _backupBusy
                                        ? null
                                        : _importData,
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
                                  SettingsTile(
                                    title: 'Send feedback',
                                    subtitle: 'Report a problem or suggest an idea.',
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const FeedbackPage(),
                                      ),
                                    ),
                                  ),
                                  SettingsTile(
                                    title: 'App version',
                                    subtitle: _appVersion.isEmpty
                                        ? 'Loading...'
                                        : _appVersion,
                                  ),
                                  SettingsTile(
                                    title: 'Licenses',
                                    subtitle: 'View open source attributions.',
                                    onTap: () => showLicensePage(
                                      context: context,
                                      applicationName: AppInfo.appName,
                                      applicationVersion: _appVersion,
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
