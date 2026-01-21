import 'package:flutter/material.dart';
import 'package:water_it/core/theme/app_spacing.dart';
import 'package:water_it/features/app_shell/presentation/pages/quick_action_info_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: spacing.lg,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _ProfileHeroCard(
                      onProfileTap: () => _openPlaceholder(
                        context,
                        title: 'Profile',
                        description:
                            'Edit your display name, avatar, and account info.',
                        icon: Icons.person_outline,
                      ),
                      onSignInTap: () => _openPlaceholder(
                        context,
                        title: 'Sign in',
                        description:
                            'Connect your account to enable cloud backup.',
                        icon: Icons.login,
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    _ProfileSection(
                      title: 'Data',
                      children: [
                        _ProfileTile(
                          title: 'Backup & Restore',
                          subtitle: 'Cloud sync or local export.',
                          onTap: () => _openPlaceholder(
                            context,
                            title: 'Backup & Restore',
                            description:
                                'Back up to the cloud or export locally for offline use.',
                            icon: Icons.backup,
                          ),
                        ),
                        _ProfileTile(
                          title: 'Export',
                          subtitle: 'Save a local copy of your data.',
                          onTap: () => _openPlaceholder(
                            context,
                            title: 'Export',
                            description:
                                'Export your plant data to a local file.',
                            icon: Icons.file_download_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: spacing.xxl,
              ),
            ),
          ],
        );
      },
    );
  }

  void _openPlaceholder(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuickActionInfoPage(
          title: title,
          description: description,
          icon: icon,
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.onProfileTap,
    required this.onSignInTap,
  });

  final VoidCallback onProfileTap;
  final VoidCallback onSignInTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person_outline, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Welcome back', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Sign in to sync your plants.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onProfileTap,
                  child: const Text('Profile'),
                ),
                FilledButton(
                  onPressed: onSignInTap,
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          color: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outline),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
