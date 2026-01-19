import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/home/domain/entities/weather_slot.dart';

final DateTime _placeholderTime = DateTime(2000, 1, 1, 12);

List<WeatherSlot> buildWeatherPlaceholders() {
  return [
    WeatherSlot(
      time: _placeholderTime,
      temperatureC: 0,
      conditionKey: 'sunny',
      cloudiness: 0,
    ),
    WeatherSlot(
      time: _placeholderTime,
      temperatureC: 0,
      conditionKey: 'cloudy',
      cloudiness: 70,
    ),
    WeatherSlot(
      time: _placeholderTime,
      temperatureC: 0,
      conditionKey: 'rainy',
      cloudiness: 90,
    ),
  ];
}

class HomeWeatherSection extends StatelessWidget {
  final List<WeatherSlot> slots;
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final double gutter;
  final bool isPlaceholder;
  final String? errorMessage;
  final String title;
  final String locationLabel;
  final String locationNote;
  final VoidCallback? onLocationTap;

  const HomeWeatherSection({
    super.key,
    required this.slots,
    required this.spacing,
    required this.colorScheme,
    required this.textTheme,
    required this.gutter,
    required this.title,
    required this.locationLabel,
    required this.locationNote,
    this.onLocationTap,
    this.isPlaceholder = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFD6CBC7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.displaySmall?.copyWith(fontSize: 28),
                ),
              ),
              GestureDetector(
                onTap: onLocationTap,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: colorScheme.onSurface,
                        ),
                        SizedBox(width: spacing.xs),
                        Text(locationLabel, style: textTheme.labelLarge),
                      ],
                    ),
                    SizedBox(height: spacing.xs),
                    Text(locationNote, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          SizedBox(
            height: 150,
            child: errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _buildVisibleSlots(slots, isPlaceholder)
                        .map(
                          (slot) => Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: gutter / 2),
                              child: _WeatherTile(
                                slot: slot.slot,
                                textTheme: textTheme,
                                isPlaceholder: slot.isPlaceholder,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeatherTile extends StatelessWidget {
  final WeatherSlot slot;
  final TextTheme textTheme;
  final bool isPlaceholder;

  const _WeatherTile({
    required this.slot,
    required this.textTheme,
    required this.isPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayLabel = DateFormat('EEE').format(slot.time);
    final timeLabel = DateFormat('h a').format(slot.time);
    final tempLabel =
        isPlaceholder ? '--' : slot.temperatureC.toStringAsFixed(0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$dayLabel $timeLabel',
          style: textTheme.titleMedium?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 6),
        _WeatherIconPlaceholder(
          colorScheme: colorScheme,
          label: slot.conditionKey,
          cloudiness: slot.cloudiness,
          isPlaceholder: isPlaceholder,
        ),
        const SizedBox(height: 6),
        Text('$tempLabeløC', style: textTheme.titleLarge),
      ],
    );
  }
}

class _WeatherSlotView {
  final WeatherSlot slot;
  final bool isPlaceholder;

  const _WeatherSlotView({
    required this.slot,
    required this.isPlaceholder,
  });
}

List<_WeatherSlotView> _buildVisibleSlots(
  List<WeatherSlot> slots,
  bool isPlaceholder,
) {
  if (slots.isEmpty) {
    return [
      _WeatherSlotView(
        slot: WeatherSlot(
          time: _placeholderTime,
          temperatureC: 0,
          conditionKey: 'sunny',
          cloudiness: 0,
        ),
        isPlaceholder: true,
      ),
      _WeatherSlotView(
        slot: WeatherSlot(
          time: _placeholderTime,
          temperatureC: 0,
          conditionKey: 'cloudy',
          cloudiness: 70,
        ),
        isPlaceholder: true,
      ),
      _WeatherSlotView(
        slot: WeatherSlot(
          time: _placeholderTime,
          temperatureC: 0,
          conditionKey: 'rainy',
          cloudiness: 90,
        ),
        isPlaceholder: true,
      ),
    ];
  }

  final padded = <_WeatherSlotView>[
    for (final slot in slots)
      _WeatherSlotView(slot: slot, isPlaceholder: isPlaceholder),
  ];

  while (padded.length < 3) {
    padded.add(
      _WeatherSlotView(
        slot: WeatherSlot(
          time: _placeholderTime,
          temperatureC: 0,
          conditionKey: 'cloudy',
          cloudiness: 70,
        ),
        isPlaceholder: true,
      ),
    );
  }

  return padded.take(3).toList();
}

class _WeatherIconPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;
  final String label;
  final int cloudiness;
  final bool isPlaceholder;

  const _WeatherIconPlaceholder({
    required this.colorScheme,
    required this.label,
    required this.cloudiness,
    required this.isPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Center(
        child: isPlaceholder
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Icon(
                  Icons.cloud_outlined,
                  color: colorScheme.primary,
                ),
              )
            : SvgPicture.asset(
                _weatherIconForCondition(label, cloudiness),
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}

String _weatherIconForCondition(String conditionKey, int cloudiness) {
  switch (conditionKey) {
    case 'sunny':
      return 'assets/images/weather/sun.svg';
    case 'cloudy':
      return cloudiness < 50
          ? 'assets/images/weather/cloudy_sun.svg'
          : 'assets/images/weather/cloudy.svg';
    case 'rainy':
    case 'storm':
      return 'assets/images/weather/rain.svg';
    default:
      return 'assets/images/weather/cloudy_sun.svg';
  }
}

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final TextTheme textTheme;

  const HomeSectionTitle({
    super.key,
    required this.title,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: textTheme.headlineSmall,
    );
  }
}
