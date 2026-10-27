import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/address.dart';
import '../../../../domain/entities/user.dart';

/// The green Grab-style header: greeting, delivery address, search entry point.
///
/// It is a plain sliver-friendly widget rather than a `SliverAppBar` because it
/// scrolls away completely - a pinned green bar eats a lot of vertical space on
/// a phone.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.onSearchTap,
    required this.onThemeToggle,
    this.user,
    super.key,
  });

  final User? user;
  final VoidCallback onSearchTap;
  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final Address? address = user?.defaultAddress;
    final String greeting = _greeting();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ContentContainer(
          padded: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              AppSpacing.md,
              context.gutter,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '$greeting, ${user?.firstName ?? 'there'} 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          _AddressLine(address: address),
                        ],
                      ),
                    ),
                    _HeaderIconButton(
                      icon: Icons.brightness_6_rounded,
                      tooltip: 'Switch theme',
                      onPressed: onThemeToggle,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _HeaderIconButton(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Notifications',
                      badge: true,
                      onPressed: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content:
                                Text('No new notifications right now.'),
                          ),
                        ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SearchEntry(onTap: onSearchTap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({this.address});

  final Address? address;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.location_on, size: 14, color: Colors.white70),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            address?.shortForm ?? 'Set your delivery address',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12.5,
            ),
          ),
        ),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: Colors.white70,
        ),
      ],
    );
  }
}

/// Looks like a text field but is a button - tapping moves to the search tab,
/// which owns the actual input and its debounce.
class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + 2,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.lightTextSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Search nasi lemak, sushi, bubble tea...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.lightTextTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                height: 22,
                width: 1,
                color: AppColors.lightBorder,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: badge
                ? Badge(
                    smallSize: 7,
                    backgroundColor: AppColors.accentAmber,
                    child: Icon(icon, size: 20, color: Colors.white),
                  )
                : Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
