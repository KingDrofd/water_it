import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/sliver_page_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = AppLayout.pagePadding(width);
          final contentMax = AppLayout.maxContentWidth(width);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMax),
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverPageHeader(
                      title: 'Settings',
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding.left,
                        spacing.sm,
                        padding.right,
                        padding.bottom,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            _SettingsSection(
                              title: 'Account',
                              children: const [
                                _SettingsTile(
                                  title: 'Profile',
                                  subtitle: 'Update your details and avatar.',
                                ),
                                _SettingsTile(
                                  title: 'Sign in',
                                  subtitle: 'Connect to sync across devices.',
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.md),
                            _SettingsSection(
                              title: 'Notifications',
                              children: const [
                                _SettingsTile(
                                  title: 'Watering reminders',
                                  subtitle: 'Manage reminder schedule.',
                                ),
                                _SettingsTile(
                                  title: 'Daily summary',
                                  subtitle: 'Get a quick morning snapshot.',
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.md),
                            _SettingsSection(
                              title: 'Weather',
                              children: const [
                                _SettingsTile(
                                  title: 'Location',
                                  subtitle: 'Choose device or city.',
                                ),
                                _SettingsTile(
                                  title: 'Units',
                                  subtitle: 'Switch between C and F.',
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.md),
                            _SettingsSection(
                              title: 'Data',
                              children: const [
                                _SettingsTile(
                                  title: 'Backup & Restore',
                                  subtitle: 'Sync or export plant data.',
                                ),
                                _SettingsTile(
                                  title: 'Export',
                                  subtitle: 'Save a local copy for offline use.',
                                ),
                              ],
                            ),
                            SizedBox(height: spacing.md),
                            _SettingsSection(
                              title: 'About',
                              children: const [
                                _SettingsTile(
                                  title: 'App version',
                                  subtitle: 'Build 0.1.0',
                                ),
                                _SettingsTile(
                                  title: 'Licenses',
                                  subtitle: 'View open source attributions.',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
