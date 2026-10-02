import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_it/core/settings/app_settings.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/theme/app_theme.dart';
import 'package:water_it/features/home/presentation/widgets/home_weather_section.dart';

void main() {
  Widget wrap(double textScale) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: HomeWeatherSection(
              slots: buildWeatherPlaceholders(),
              spacing: const AppSpacing(),
              colorScheme: Theme.of(context).colorScheme,
              textTheme: Theme.of(context).textTheme,
              gutter: 12,
              locationLabel: 'San Francisco, CA',
              locationNote: 'Default location',
              temperatureUnit: TemperatureUnit.celsius,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('weather slots lay out without overflowing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('and still fits at a large text scale', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(1.4));

    expect(tester.takeException(), isNull);
  });
}
