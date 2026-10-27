import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/usecases/catalog_usecases.dart';
import '../bloc/food_detail_cubit.dart';
import 'widgets/add_to_cart_sheet.dart';

/// Full dish page: image, description, ingredients, nutrition and reviews.
class FoodDetailScreen extends StatelessWidget {
  const FoodDetailScreen({required this.foodItemId, super.key});

  final String foodItemId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FoodDetailCubit>(
      create: (_) => FoodDetailCubit(
        getFoodDetail: sl<GetFoodDetail>(),
        catalog: sl<CatalogRepository>(),
      )..load(foodItemId),
      child: _FoodDetailView(foodItemId: foodItemId),
    );
  }
}

class _FoodDetailView extends StatelessWidget {
  const _FoodDetailView({required this.foodItemId});

  final String foodItemId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoodDetailCubit, FoodDetailState>(
      builder: (BuildContext context, FoodDetailState state) {
        if (state.isLoading) return const _FoodSkeleton();

        if (state.status == FoodDetailStatus.failure || state.detail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: state.errorMessage ?? 'Could not load this dish.',
              onRetry: () =>
                  context.read<FoodDetailCubit>().load(foodItemId),
            ),
          );
        }

        final FoodItem item = state.detail!.item;

        return Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: AppImage(
                    seed: item.id,
                    emoji: item.emoji,
                    imageUrl: item.imageUrl,
                    borderRadius: BorderRadius.zero,
                    emojiScale: 0.36,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ContentContainer(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xl,
                      bottom: AppSpacing.huge * 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _Header(item: item),
                        const AppDivider(),
                        _Description(item: item),
                        if (item.ingredients.isNotEmpty) ...<Widget>[
                          const AppDivider(),
                          _Ingredients(item: item),
                        ],
                        if (item.allergens.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.lg),
                          _Allergens(item: item),
                        ],
                        const AppDivider(),
                        _Nutrition(item: item),
                        if (state.reviews.isNotEmpty) ...<Widget>[
                          const AppDivider(),
                          _DishReviews(reviews: state.reviews),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _AddBar(state: state),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(item.name, style: theme.textTheme.headlineSmall),
            ),
            if (item.isOnOffer)
              InfoPill(
                label: '${item.discountPercent}% off',
                icon: Icons.local_offer_rounded,
                color: AppColors.danger,
                filled: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () =>
              context.push(Routes.restaurantDetail(item.restaurantId)),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.storefront_rounded,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                item.restaurantName,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppColors.primary),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Text(
              Formatters.currency(item.effectivePrice),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: item.isOnOffer ? AppColors.danger : null,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (item.isOnOffer) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Text(
                Formatters.currency(item.priceMyr),
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            if (item.reviewCount > 0)
              InfoPill(
                label:
                    '${Formatters.rating(item.rating)} (${Formatters.compactCount(item.reviewCount)})',
                icon: Icons.star_rounded,
                color: AppColors.accentAmber,
                filled: true,
              ),
            InfoPill(
              label: '${item.prepMinutes} min prep',
              icon: Icons.schedule_rounded,
            ),
            if (item.isVegetarian)
              const InfoPill(
                label: 'Vegetarian',
                icon: Icons.eco_rounded,
                color: AppColors.success,
                filled: true,
              ),
            if (item.isSpicy)
              InfoPill(
                label: 'Spicy ${'🌶️' * item.spiceLevel.clamp(1, 3)}',
                color: AppColors.danger,
                filled: true,
              ),
            if (item.servingSize != null)
              InfoPill(
                label: item.servingSize!,
                icon: Icons.restaurant_rounded,
              ),
          ],
        ),
      ],
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Description', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(item.description, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _Ingredients extends StatelessWidget {
  const _Ingredients({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Ingredients', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: item.ingredients
              .map(
                (String ingredient) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border:
                        Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(ingredient, style: theme.textTheme.bodySmall),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _Allergens extends StatelessWidget {
  const _Allergens({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Contains', style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  item.allergens.join(', '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Nutrition extends StatelessWidget {
  const _Nutrition({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('At a glance', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            _Fact(
              label: 'Calories',
              value: item.calories == null ? '-' : '${item.calories} kcal',
              icon: Icons.local_fire_department_outlined,
            ),
            _Fact(
              label: 'Prep time',
              value: '${item.prepMinutes} min',
              icon: Icons.timer_outlined,
            ),
            _Fact(
              label: 'Diet',
              value: item.isVegetarian ? 'Vegetarian' : 'Contains meat',
              icon: Icons.restaurant_menu_rounded,
            ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _DishReviews extends StatelessWidget {
  const _DishReviews({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'What people said about this dish',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final Review review in reviews.take(5)) ...<Widget>[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      review.userAvatarEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        review.userName,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    RatingBadge(rating: review.rating, compact: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(review.comment, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  Formatters.relative(review.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Sticky add-to-cart bar.
class _AddBar extends StatelessWidget {
  const _AddBar({required this.state});

  final FoodDetailState state;

  @override
  Widget build(BuildContext context) {
    final FoodItem? item = state.detail?.item;
    if (item == null) return const SizedBox.shrink();

    final String label = switch (state) {
      FoodDetailState(restaurant: null) => 'Unavailable',
      FoodDetailState(restaurant: final r?) when !r.isOpen => 'Restaurant closed',
      _ when !item.isAvailable => 'Sold out',
      _ => 'Add to cart • ${Formatters.currency(item.effectivePrice)}',
    };

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: AppButton(
        label: label,
        icon: state.canAddToCart ? Icons.shopping_bag_outlined : null,
        onPressed: state.canAddToCart
            ? () => AddToCartSheet.show(
                  context,
                  item: item,
                  restaurant: state.restaurant!,
                )
            : null,
      ),
    );
  }
}

class _FoodSkeleton extends StatelessWidget {
  const _FoodSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: EdgeInsets.all(context.gutter),
        children: const <Widget>[
          AppShimmer(child: SkeletonBox(height: 220, radius: AppRadius.lg)),
          SizedBox(height: AppSpacing.xl),
          AppShimmer(child: SkeletonBox(width: 240, height: 24)),
          SizedBox(height: AppSpacing.md),
          AppShimmer(child: SkeletonBox(width: 140, height: 16)),
          SizedBox(height: AppSpacing.xxl),
          AppShimmer(child: SkeletonBox(width: double.infinity, height: 14)),
          SizedBox(height: AppSpacing.sm),
          AppShimmer(child: SkeletonBox(width: double.infinity, height: 14)),
          SizedBox(height: AppSpacing.sm),
          AppShimmer(child: SkeletonBox(width: 200, height: 14)),
        ],
      ),
    );
  }
}
