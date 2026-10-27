import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cubit/theme_cubit.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/config/app_config.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/link_launcher.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/article_credit.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/datasources/local/demo_data_source.dart';
import '../../../domain/entities/user.dart';
import '../../auth/bloc/auth_bloc.dart';

/// Account hub: identity card, shortcuts, preferences and sign-out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<AuthBloc>().state.user;

    if (user == null) {
      return const Scaffold(
        body: EmptyView(
          title: 'Not signed in',
          icon: Icons.person_outline_rounded,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          context.gutter,
          AppSpacing.lg,
          context.gutter,
          AppSpacing.huge,
        ),
        children: <Widget>[
          ContentContainer(
            padded: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _IdentityCard(user: user),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Your account'),
                _MenuTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal information',
                  subtitle: 'Name, phone number and avatar',
                  onTap: () => context.push(Routes.editProfile),
                ),
                _MenuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Saved addresses',
                  subtitle:
                      '${user.addresses.length} saved • delivering to '
                      '${user.defaultAddress?.label.display ?? 'nowhere yet'}',
                  onTap: () => context.push(Routes.addresses),
                ),
                _MenuTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Favourite restaurants',
                  subtitle:
                      '${user.favouriteRestaurantIds.length} saved for later',
                  onTap: () => context.push(Routes.favourites),
                ),
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Order history',
                  subtitle: 'Past orders and receipts',
                  onTap: () => context.go(Routes.orders),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Preferences'),
                const _ThemeTile(),
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Order updates and promotions',
                  trailing: Switch(value: true, onChanged: (_) {}),
                  onTap: null,
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Demo controls'),
                _MenuTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset demo data',
                  subtitle: 'Restore the seeded restaurants, menus and orders',
                  onTap: () => _resetDemoData(context),
                ),
                _MenuTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Read the article',
                  subtitle:
                      'The ${AppConfig.instance.publisher} write-up this demo '
                      'was built for',
                  onTap: () => LinkLauncher.open(
                    context,
                    AppConfig.instance.articleUrl,
                  ),
                ),
                _MenuTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About this app',
                  subtitle:
                      '${AppConfig.instance.appName} • '
                      '${AppConfig.instance.backend.name} backend',
                  onTap: () => _showAbout(context),
                ),
                const SizedBox(height: AppSpacing.xl),
                const ArticleCredit(),
                const SizedBox(height: AppSpacing.xxl),
                OutlinedButton.icon(
                  onPressed: () => _confirmSignOut(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final AuthBloc auth = context.read<AuthBloc>();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your cart and saved addresses stay on this device.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) auth.add(const AuthSignOutRequested());
  }

  void _resetDemoData(BuildContext context) {
    DemoDataSource.instance.reset();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Demo data reset. Pull to refresh any open list.'),
        ),
      );
  }

  void _showAbout(BuildContext context) {
    final AppConfig config = AppConfig.instance;

    showAboutDialog(
      context: context,
      applicationName: config.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Padding(
        padding: EdgeInsets.only(right: AppSpacing.sm),
        child: AppLogo(size: 44),
      ),
      applicationLegalese:
          'A portfolio Flutter demo by ${config.publisher}. Restaurants, '
          'dishes, reviews and orders are fictional seed data.',
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        Text(
          'Clean Architecture with BLoC, GoRouter and GetIt. '
          'Backend: ${config.backend.name}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        const ArticleCredit(compact: true),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.avatarEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  user.memberTier,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              _Stat(
                value: Formatters.compactCount(user.loyaltyPoints),
                label: 'Points',
              ),
              _Stat(
                value: '${user.addresses.length}',
                label: 'Addresses',
              ),
              _Stat(
                value: '${user.favouriteRestaurantIds.length}',
                label: 'Favourites',
              ),
            ],
          ),
          if (user.role != UserRole.customer) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Signed in as ${user.role.label}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Member since ${user.createdAt == null ? '2024' : Formatters.date(user.createdAt!)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 19),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (BuildContext context, ThemeMode mode) {
        final ThemeCubit cubit = context.read<ThemeCubit>();
        return _MenuTile(
          icon: cubit.icon,
          title: 'Appearance',
          subtitle: cubit.label,
          onTap: cubit.cycle,
          trailing: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded, size: 16),
                tooltip: 'System',
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded, size: 16),
                tooltip: 'Light',
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded, size: 16),
                tooltip: 'Dark',
              ),
            ],
            selected: <ThemeMode>{mode},
            onSelectionChanged: (Set<ThemeMode> selection) =>
                cubit.set(selection.first),
          ),
        );
      },
    );
  }
}
