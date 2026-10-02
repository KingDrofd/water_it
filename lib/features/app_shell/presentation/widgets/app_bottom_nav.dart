import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_colors.dart';

class AppNavDestination {
  const AppNavDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Floating bottom bar from the M6 design: page destinations on the left and
/// the Add Plant pill on the right, which is an action rather than a tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddPlant,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddPlant;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.navBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < destinations.length; i++) ...[
            Expanded(
              child: _NavItem(
                destination: destinations[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
                labelStyle: labelStyle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            flex: 3,
            child: _AddPlantPill(onTap: onAddPlant),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.labelStyle,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = selected ? palette.deep : palette.muted;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: Material(
        color: selected ? palette.card2 : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(destination.icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  style: labelStyle?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPlantPill extends StatelessWidget {
  const _AddPlantPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: palette.accent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: palette.onAccent),
              const SizedBox(width: 6),
              Text(
                'Add Plant',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: palette.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
