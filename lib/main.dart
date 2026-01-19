import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:water_it/core/di/service_locator.dart';
import 'package:water_it/core/theme/app_theme.dart';
import 'package:water_it/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:water_it/features/plants/presentation/bloc/plant_list_cubit.dart';
import 'package:water_it/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  runApp(const WaterItApp());
}

class WaterItApp extends StatelessWidget {
  const WaterItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'Water It',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
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
