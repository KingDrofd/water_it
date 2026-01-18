import 'package:flutter/material.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: theme.textTheme.titleMedium,
      elevation: 4,
    );

    if (icon == null) {
      return ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: icon!,
      label: Text(label),
    );
  }
}
