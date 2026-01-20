import 'package:flutter/material.dart';
import 'package:water_it/core/layout/app_layout.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/core/widgets/app_bars/sliver_page_header.dart';

enum SettingsSection {
  notifications,
  weather,
  about,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.initialSection,
  });

  final SettingsSection? initialSection;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  late final Map<SettingsSection, GlobalKey> _sectionKeys = {
    SettingsSection.notifications: GlobalKey(),
    SettingsSection.weather: GlobalKey(),
    SettingsSection.about: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final section = widget.initialSection;
      if (section != null) {
        _scrollToSection(section);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(SettingsSection section) {
    final targetContext = _sectionKeys[section]?.currentContext;
    if (targetContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

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
                  controller: _scrollController,
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
                            KeyedSubtree(
                              key: _sectionKeys[SettingsSection.notifications],
                              child: _SettingsSection(
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
                            ),
                            SizedBox(height: spacing.md),
                            KeyedSubtree(
                              key: _sectionKeys[SettingsSection.weather],
                              child: _SettingsSection(
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
                            ),
                            SizedBox(height: spacing.md),
                            KeyedSubtree(
                              key: _sectionKeys[SettingsSection.about],
                              child: _SettingsSection(
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
