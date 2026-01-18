import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gutter = AppLayout.gutter(width);

        return ListView(
          padding: EdgeInsets.only(
            left: spacing.lg,
            right: spacing.lg,
            top: AppLayout.navBarInset(width, spacing: spacing.xxl+spacing.xxl),
            bottom: AppLayout.navBarInset(width, spacing: spacing.xxl),
          ),
          children: [
            _SectionTitle(title: "Today's Weather", textTheme: textTheme),
            SizedBox(height: spacing.sm),
            _WeatherCard(
              spacing: spacing,
              colorScheme: colorScheme,
              textTheme: textTheme,
              gutter: gutter,
            ),
            SizedBox(height: spacing.lg),
            _SectionTitle(title: 'Reminders', textTheme: textTheme),
            SizedBox(height: spacing.sm),
            _ReminderStrip(
              spacing: spacing,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            SizedBox(height: spacing.xxl),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final TextTheme textTheme;

  const _SectionTitle({
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

class _WeatherCard extends StatelessWidget {
  final AppSpacing spacing;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final double gutter;

  const _WeatherCard({
    required this.spacing,
    required this.colorScheme,
    required this.textTheme,
    required this.gutter,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _WeatherSlot(time: '12 pm', temp: '29', uv: 'UV: 3'),
      _WeatherSlot(time: '2 pm', temp: '31', uv: 'UV: 5'),
      _WeatherSlot(time: '5 pm', temp: '32', uv: 'UV: 2'),
    ];

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (slot) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter / 2),
                  child: _WeatherTile(slot: slot, textTheme: textTheme),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _WeatherSlot {
  final String time;
  final String temp;
  final String uv;

  const _WeatherSlot({
    required this.time,
    required this.temp,
    required this.uv,
  });
}

class _WeatherTile extends StatelessWidget {
  final _WeatherSlot slot;
  final TextTheme textTheme;

  const _WeatherTile({
    required this.slot,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(slot.time, style: textTheme.labelLarge),
        const SizedBox(height: 6),
        _WeatherIcon(colorScheme: colorScheme),
        const SizedBox(height: 6),
        Text('${slot.temp}°C', style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(slot.uv, style: textTheme.bodySmall),
      ],
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  final ColorScheme colorScheme;

  const _WeatherIcon({
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFFFC107),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 54,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline),
          ),
        ),
      ],
    );
  }
}

class _ReminderStrip extends StatelessWidget {
  final AppSpacing spacing;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _ReminderStrip({
    required this.spacing,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _ReminderItem(label: 'Plant 1', task: 'Pruning', icon: Icons.spa),
      _ReminderItem(label: 'Plant 2', task: 'Watering', icon: Icons.water_drop),
      _ReminderItem(
        label: 'Plant 3',
        task: 'Watering and Pruning',
        icon: Icons.local_florist,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.sm),
                  child: _ReminderTile(
                    item: item,
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ReminderItem {
  final String label;
  final String task;
  final IconData icon;

  const _ReminderItem({
    required this.label,
    required this.task,
    required this.icon,
  });
}

class _ReminderTile extends StatelessWidget {
  final _ReminderItem item;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _ReminderTile({
    required this.item,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.label, style: textTheme.labelLarge),
        SizedBox(height: 8),
        Icon(item.icon, color: colorScheme.primary, size: 36),
        SizedBox(height: 8),
        Text(
          item.task,
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
