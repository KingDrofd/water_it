import 'package:flutter/material.dart';

enum QuickAction {
  settings,
  about,
  feedback,
}

class QuickActionsDrawer extends StatelessWidget {
  const QuickActionsDrawer({
    super.key,
    required this.onActionSelected,
  });

  final ValueChanged<QuickAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const _DrawerTitle(text: 'Quick Actions'),
              const SizedBox(height: 8),
              _QuickActionTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => onActionSelected(QuickAction.settings),
              ),
              _QuickActionTile(
                icon: Icons.info_outline,
                label: 'About',
                onTap: () => onActionSelected(QuickAction.about),
              ),
              _QuickActionTile(
                icon: Icons.feedback_outlined,
                label: 'Feedback',
                onTap: () => onActionSelected(QuickAction.feedback),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTitle extends StatelessWidget {
  final String text;

  const _DrawerTitle({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: textTheme.displaySmall?.copyWith(fontSize: 22),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
