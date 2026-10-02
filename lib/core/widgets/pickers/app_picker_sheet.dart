import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_colors.dart';
import 'package:water_it/core/theme/app_spacing.dart';

/// One row of an [showAppPicker] sheet.
class AppPickerOption<T> {
  const AppPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  /// Draws the row in the overdue/error colour, for actions like Delete.
  final bool isDestructive;
}

/// What the picker returned. Wrapping the value keeps "dismissed" (null
/// result) distinguishable from "chose the Not set row" (a result holding
/// null), so a field can still be cleared.
class AppPickerSelection<T> {
  const AppPickerSelection(this.value);

  final T value;
}

/// The app's one way to choose from a short list — used for form pickers and
/// action menus alike.
///
/// Material's dropdown and popup menus bring their own corners, type scale
/// and pop animation, none of which match the design; a sheet keeps every
/// choice on the same rounded surface with the same slide-up motion as the
/// Add Plant sheet.
Future<AppPickerSelection<T>?> showAppPicker<T>(
  BuildContext context, {
  required String title,
  required List<AppPickerOption<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<AppPickerSelection<T>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _PickerSheet<T>(
      title: title,
      options: options,
      selected: selected,
    ),
  );
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<AppPickerOption<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            SizedBox(height: spacing.md),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = options[index];
                  return _PickerRow<T>(
                    option: option,
                    isSelected: selected != null && option.value == selected,
                    onTap: () => Navigator.of(context)
                        .pop(AppPickerSelection(option.value)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow<T> extends StatelessWidget {
  const _PickerRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final AppPickerOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final tint = option.isDestructive
        ? palette.overdueInk
        : option.iconColor ?? palette.deep;

    return Material(
      color: isSelected ? palette.card2 : palette.bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (option.icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(option.icon, size: 20, color: tint),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: textTheme.titleSmall?.copyWith(
                        color: option.isDestructive ? palette.overdueInk : null,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: palette.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, color: palette.deep, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A form field that looks like the app's text inputs but opens
/// [showAppPicker] instead of a Material dropdown.
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.placeholder = 'Not set',
  });

  final String label;
  final T? value;
  final List<AppPickerOption<T?>> options;
  final ValueChanged<T?> onChanged;
  final String placeholder;

  String get _valueLabel {
    for (final option in options) {
      if (option.value == value && option.value != null) {
        return option.label;
      }
    }
    return placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hasValue = value != null;

    return Semantics(
      button: true,
      label: '$label: $_valueLabel',
      child: Material(
        color: palette.card2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final choice = await showAppPicker<T?>(
              context,
              title: label,
              options: options,
              selected: value,
            );
            if (choice != null) {
              onChanged(choice.value);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: textTheme.labelMedium
                            ?.copyWith(color: palette.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _valueLabel,
                        style: textTheme.titleSmall?.copyWith(
                          color: hasValue ? palette.ink : palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.expand_more_rounded, color: palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
