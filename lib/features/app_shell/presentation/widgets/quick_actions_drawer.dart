import 'package:flutter/material.dart';

class QuickActionsDrawer extends StatelessWidget {
  const QuickActionsDrawer({super.key});

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
            children: const [
              _DrawerTitle(text: 'Quick Actions'),
              SizedBox(height: 8),
              _QuickActionTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
              ),
              _QuickActionTile(
                icon: Icons.local_florist_outlined,
                label: 'My Plants',
              ),
              _QuickActionTile(
                icon: Icons.backup,
                label: 'Backup & Restore',
              ),
              _QuickActionTile(
                icon: Icons.info_outline,
                label: 'About',
              ),
              _QuickActionTile(
                icon: Icons.feedback_outlined,
                label: 'Feedback',
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

  const _QuickActionTile({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(),
    );
  }
}
