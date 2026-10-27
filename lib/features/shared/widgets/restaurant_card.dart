import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/restaurant.dart';

/// Large restaurant card used in the home rails and the browse grid.
///
/// Entity-aware and reused across four screens, which is why it lives in
/// `features/shared/` rather than inside any one feature.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    required this.restaurant,
    this.width,
    this.isFavourite = false,
    this.onFavouriteToggle,
    super.key,
  });

  final Restaurant restaurant;

  /// Fixed width for horizontal rails; null lets it fill a grid cell.
  final double? width;
  final bool isFavourite;
  final VoidCallback? onFavouriteToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool closed = !restaurant.isOpen;

    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push(Routes.restaurantDetail(restaurant.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ColorFiltered(
                    // Closed restaurants are desaturated rather than hidden, so
                    // people can still browse and plan.
                    colorFilter: closed
                        ? const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                    child: AppImage(
                      seed: restaurant.id,
                      emoji: restaurant.emoji,
                      imageUrl: restaurant.coverImageUrl,
                      borderRadius: BorderRadius.zero,
                      emojiScale: 0.34,
                    ),
                  ),
                ),
                if (restaurant.promoText != null)
                  Positioned(
                    left: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: _PromoRibbon(text: restaurant.promoText!),
                  ),
                if (closed)
                  const Positioned.fill(child: _ClosedOverlay()),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: _FavouriteButton(
                    isFavourite: isFavourite,
                    onPressed: onFavouriteToggle,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.cuisineLabel} • ${restaurant.priceLevelLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      RatingBadge(
                        rating: restaurant.rating,
                        reviewCount:
                            Formatters.compactCount(restaurant.reviewCount),
                        compact: true,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('•', style: theme.textTheme.bodySmall),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          Formatters.etaRange(
                            restaurant.etaMinMinutes,
                            restaurant.etaMaxMinutes,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Icon(
                        restaurant.hasFreeDelivery
                            ? Icons.local_shipping_rounded
                            : Icons.local_shipping_outlined,
                        size: 14,
                        color: restaurant.hasFreeDelivery
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.hasFreeDelivery
                            ? 'Free delivery'
                            : Formatters.currency(restaurant.deliveryFeeMyr),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: restaurant.hasFreeDelivery
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.distance(restaurant.distanceKm),
                        style: theme.textTheme.labelSmall,
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

/// Compact horizontal variant used in favourites and search results.
class RestaurantListTile extends StatelessWidget {
  const RestaurantListTile({
    required this.restaurant,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Restaurant restaurant;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap ??
          () => context.push(Routes.restaurantDetail(restaurant.id)),
      child: Row(
        children: <Widget>[
          AppImage(
            seed: restaurant.id,
            emoji: restaurant.emoji,
            imageUrl: restaurant.imageUrl,
            height: 76,
            width: 76,
            emojiScale: 0.44,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (!restaurant.isOpen)
                      const InfoPill(
                        label: 'Closed',
                        color: AppColors.danger,
                        filled: true,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  restaurant.cuisineLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    RatingBadge(rating: restaurant.rating, compact: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${Formatters.etaRange(restaurant.etaMinMinutes, restaurant.etaMaxMinutes)}'
                        ' • ${Formatters.distance(restaurant.distanceKm)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _PromoRibbon extends StatelessWidget {
  const _PromoRibbon({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentOrange,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.local_offer_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedOverlay extends StatelessWidget {
  const _ClosedOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.42),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Text(
            'Closed for now',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF13161C),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.isFavourite, this.onPressed});

  final bool isFavourite;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) return const SizedBox.shrink();

    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: isFavourite ? AppColors.danger : const Color(0xFF5B6472),
          ),
        ),
      ),
    );
  }
}
