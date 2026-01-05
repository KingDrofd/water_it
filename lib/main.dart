import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:water_it/l10n/app_localizations.dart';
import 'package:water_it/features/plants/presentation/pages/plant_list_page.dart';

void main() {
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const PlantListPage(),
    );
  }
}
