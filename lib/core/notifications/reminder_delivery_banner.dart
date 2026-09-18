import 'package:flutter/material.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/notifications/reminder_permission_flow.dart';
import 'package:water_it/core/theme/app_spacing.dart';

/// Surfaces the one case the app can't fix on its own: reminders are on, but
/// Android won't deliver them (or won't deliver them on time).
///
/// Shows nothing at all when everything is healthy, so it costs the user no
/// attention in the normal case.
class ReminderDeliveryBanner extends StatefulWidget {
  const ReminderDeliveryBanner({super.key});

  @override
  State<ReminderDeliveryBanner> createState() => _ReminderDeliveryBannerState();
}

class _ReminderDeliveryBannerState extends State<ReminderDeliveryBanner>
    with WidgetsBindingObserver {
  NotificationReadiness? _readiness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final readiness = await getIt<NotificationService>().readiness();
      if (mounted) {
        setState(() => _readiness = readiness);
      }
    } catch (_) {
      // Leave the banner hidden rather than guessing at a problem.
    }
  }

  Future<void> _fix() async {
    final readiness = _readiness;
    if (readiness != null && readiness.blocked) {
      await getIt<NotificationService>().requestPermissions();
    } else if (mounted) {
      await ReminderPermissionFlow.requestExactAlarms(context);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final readiness = _readiness;
    final shouldWarn = readiness != null &&
        (readiness.blocked ||
            (ReminderPermissionFlow.exactAlarmPromptsEnabled &&
                readiness.imprecise));
    if (!shouldWarn) {
      return const SizedBox.shrink();
    }

    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final message = readiness.blocked
        ? 'Notifications are switched off, so reminders will not arrive.'
        : 'Android may delay your reminders by hours until precise timing is allowed.';

    return Container(
      margin: EdgeInsets.only(bottom: spacing.md),
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 20,
            color: colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          SizedBox(width: spacing.xs),
          TextButton(
            onPressed: _fix,
            child: const Text('Fix'),
          ),
        ],
      ),
    );
  }
}
