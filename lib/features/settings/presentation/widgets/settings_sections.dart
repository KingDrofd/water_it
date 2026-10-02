import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/core/settings/app_settings.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Card(
          margin: EdgeInsets.zero,
          color: palette.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: palette.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 8,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: palette.line,
                  ),
                Material(
                  color: Colors.transparent,
                  child: children[i],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isLoading,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: isLoading ? null : onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class SettingsUnitsTile extends StatelessWidget {
  const SettingsUnitsTile({
    super.key,
    required this.unit,
    required this.isLoading,
    required this.onChanged,
  });

  final TemperatureUnit unit;
  final bool isLoading;
  final ValueChanged<TemperatureUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: const Text('Units'),
      subtitle: const Text('Switch between °C and °F.'),
      trailing: SegmentedButton<TemperatureUnit>(
        segments: const [
          ButtonSegment(
            value: TemperatureUnit.celsius,
            label: Text('°C'),
          ),
          ButtonSegment(
            value: TemperatureUnit.fahrenheit,
            label: Text('°F'),
          ),
        ],
        selected: {unit},
        onSelectionChanged:
            isLoading ? null : (value) => onChanged(value.first),
        showSelectedIcon: false,
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
