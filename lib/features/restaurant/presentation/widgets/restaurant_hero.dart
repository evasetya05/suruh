import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/restaurant.dart';

/// Collapsing hero for the restaurant page.
///
/// The title only appears once the image has collapsed behind the app bar,
/// which keeps the expanded state clean and the collapsed state readable.
class RestaurantHero extends StatelessWidget {
  const RestaurantHero({
    required this.restaurant,
    required this.isFavourite,
    required this.onFavouriteToggle,
    super.key,
  });

  final Restaurant restaurant;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: const _CircleBackButton(),
      actions: <Widget>[
        _CircleAction(
          icon: isFavourite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: isFavourite ? AppColors.danger : null,
          tooltip: isFavourite ? 'Remove from favourites' : 'Save to favourites',
          onPressed: onFavouriteToggle,
        ),
        _CircleAction(
          icon: Icons.share_outlined,
          tooltip: 'Share',
          onPressed: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Shared ${restaurant.name} (demo action)'),
              ),
            ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsets.symmetric(
          horizontal: 56,
          vertical: AppSpacing.md,
        ),
        title: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool collapsed = constraints.biggest.height <= 92;
            return AnimatedOpacity(
              opacity: collapsed ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Text(
                restaurant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          },
        ),
        background: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AppImage(
              seed: restaurant.id,
              emoji: restaurant.emoji,
              imageUrl: restaurant.coverImageUrl,
              borderRadius: BorderRadius.zero,
              emojiScale: 0.3,
            ),
            // Scrim so the white overlay text and buttons stay legible against
            // any gradient the plate generates.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withValues(alpha: 0.32),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const <double>[0, 0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (restaurant.promoText != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        restaurant.promoText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Text(
                    restaurant.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      shadows: <Shadow>[
                        Shadow(blurRadius: 10, color: Colors.black38),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '${restaurant.cuisineLabel} • ${restaurant.priceLevelLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (!restaurant.isOpen)
                        const InfoPill(
                          label: 'Closed',
                          color: AppColors.danger,
                          filled: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _CircleAction(
        icon: Icons.arrow_back_rounded,
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(
                icon,
                size: 20,
                color: color ?? const Color(0xFF13161C),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
