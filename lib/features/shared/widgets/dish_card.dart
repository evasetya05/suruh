import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/food_item.dart';

/// Vertical dish card for the "Popular" and "Offers" rails.
class DishCard extends StatelessWidget {
  const DishCard({required this.item, this.width = 176, super.key});

  final FoodItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push(Routes.foodDetail(item.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1.25,
                  child: AppImage(
                    seed: item.id,
                    emoji: item.emoji,
                    imageUrl: item.imageUrl,
                    borderRadius: BorderRadius.zero,
                    emojiScale: 0.42,
                  ),
                ),
                if (item.isOnOffer)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _DiscountBadge(percent: item.discountPercent),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PriceRow(item: item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal menu row used inside the restaurant page and search results.
class DishListTile extends StatelessWidget {
  const DishListTile({
    required this.item,
    this.trailing,
    this.onTap,
    this.showRestaurant = false,
    super.key,
  });

  final FoodItem item;

  /// Usually the add button or a quantity stepper.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showRestaurant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool soldOut = !item.isAvailable;

    return Opacity(
      opacity: soldOut ? 0.55 : 1,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: soldOut
            ? null
            : (onTap ?? () => context.push(Routes.foodDetail(item.id))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (item.isVegetarian) ...<Widget>[
                        const _DietDot(color: AppColors.success),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (item.isSpicy) ...<Widget>[
                        const SizedBox(width: 4),
                        Text('🌶️' * item.spiceLevel.clamp(1, 3),
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ],
                  ),
                  if (showRestaurant) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      item.restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PriceRow(item: item),
                  if (item.reviewCount > 0) ...<Widget>[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        RatingBadge(
                          rating: item.rating,
                          reviewCount:
                              Formatters.compactCount(item.reviewCount),
                          compact: true,
                        ),
                        if (item.isPopular)
                          const InfoPill(
                            label: 'Popular',
                            icon: Icons.trending_up_rounded,
                            color: AppColors.accentOrange,
                            filled: true,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    AppImage(
                      seed: item.id,
                      emoji: item.emoji,
                      imageUrl: item.imageUrl,
                      height: 92,
                      width: 92,
                      emojiScale: 0.46,
                    ),
                    if (soldOut)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Center(
                            child: Text(
                              'Sold out',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (trailing != null && !soldOut) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Wrap, not Row: a discounted price shows two amounts side by side, which
    // does not fit a narrow card at larger text scales.
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          Formatters.currencyCompact(item.effectivePrice),
          style: theme.textTheme.titleSmall?.copyWith(
            color: item.isOnOffer ? AppColors.danger : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (item.isOnOffer)
          Text(
            Formatters.currencyCompact(item.priceMyr),
            style: theme.textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// The square dot used on Indian and Malaysian menus to mark vegetarian items.
class _DietDot extends StatelessWidget {
  const _DietDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          height: 5,
          width: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
