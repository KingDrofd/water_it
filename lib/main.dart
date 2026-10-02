import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:water_it/core/app_info/app_info.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/notifications/notification_payload.dart';
import 'package:water_it/core/notifications/notification_service.dart';
import 'package:water_it/core/theme/app_theme.dart';
import 'package:water_it/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/features/plants/presentation/pages/plant_detail_page.dart';
import 'package:water_it/l10n/app_localizations.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  await setupLocator();
  _wireNotificationCallbacks();
  runApp(const WaterItApp());
  await _openPlantFromLaunchNotification();
}

/// The bundled fonts are SIL Open Font License; the licence has to travel
/// with them, so it is listed on the Licenses page beside the packages'.
void _registerFontLicenses() {
  const fonts = {
    'Pacifico': 'assets/fonts/Pacifico/OFL.txt',
    'Quicksand': 'assets/fonts/Quicksand/OFL.txt',
    'Raleway': 'assets/fonts/Raleway/OFL.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final entry in fonts.entries) {
      final text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}

void _wireNotificationCallbacks() {
  NotificationService.onPlantTap = (plantId) {
    appNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => PlantDetailPage(plantId: plantId)),
    );
  };
  // After an in-app "Mark done" action, reload so the home strip, badges,
  // and schedules reflect the new completion.
  NotificationService.onActionHandled = () async {
    await getIt<PlantListCubit>().loadPlants();
  };
}

/// When the app was cold-started by tapping a reminder, open that plant.
Future<void> _openPlantFromLaunchNotification() async {
  final launchDetails = await getIt<NotificationService>()
      .getLaunchDetails();
  final response = launchDetails?.notificationResponse;
  if (launchDetails?.didNotificationLaunchApp != true || response == null) {
    return;
  }
  if (response.actionId != null) {
    return; // Action buttons are handled by the background handler.
  }
  final payload = NotificationPayload.decode(response.payload);
  if (payload != null && payload.plantId.isNotEmpty) {
    NotificationService.onPlantTap?.call(payload.plantId);
  }
}

class WaterItApp extends StatelessWidget {
  const WaterItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: AppInfo.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scaler = AppTheme.textScalerForWidth(mediaQuery.size.width);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: scaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: getIt<PlantListCubit>()..loadPlants(),
          ),
        ],
        child: const AppShellPage(),
      ),
    );
  }
}
