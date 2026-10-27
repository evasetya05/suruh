import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/service_locator.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/food_category.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/catalog_usecases.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../food/presentation/widgets/add_to_cart_sheet.dart';
import '../../shared/widgets/dish_card.dart';
import '../bloc/restaurant_bloc.dart';
import 'widgets/restaurant_hero.dart';
import 'widgets/reviews_tab.dart';

/// Restaurant page: hero, info strip, then Menu / Reviews / Info tabs.
class RestaurantScreen extends StatelessWidget {
  const RestaurantScreen({required this.restaurantId, super.key});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;

    return BlocProvider<RestaurantBloc>(
      create: (_) => RestaurantBloc(
        getDetail: sl<GetRestaurantDetail>(),
        toggleFavourite: sl<ToggleFavourite>(),
      )..add(
          RestaurantRequested(
            restaurantId: restaurantId,
            isFavourite:
                user?.favouriteRestaurantIds.contains(restaurantId) ?? false,
          ),
        ),
      child: _RestaurantView(restaurantId: restaurantId),
    );
  }
}

class _RestaurantView extends StatelessWidget {
  const _RestaurantView({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantBloc, RestaurantState>(
      builder: (BuildContext context, RestaurantState state) {
        if (state.isLoading) return const _RestaurantSkeleton();

        if (state.status == RestaurantStatus.failure || state.detail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: state.errorMessage ?? 'Could not load this restaurant.',
              onRetry: () => context.read<RestaurantBloc>().add(
                    RestaurantRequested(restaurantId: restaurantId),
                  ),
            ),
          );
        }

        final RestaurantDetail detail = state.detail!;
        final Restaurant restaurant = detail.restaurant;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool _) =>
                  <Widget>[
                RestaurantHero(
                  restaurant: restaurant,
                  isFavourite: state.isFavourite,
                  onFavouriteToggle: () => _toggleFavourite(context),
                ),
                SliverToBoxAdapter(
                  child: ContentContainer(
                    child: _InfoStrip(restaurant: restaurant),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      tabs: <Widget>[
                        Tab(text: 'Menu (${detail.menu.length})'),
                        Tab(text: 'Reviews (${detail.reviews.length})'),
                        const Tab(text: 'Info'),
                      ],
                    ),
                    Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
              body: TabBarView(
                children: <Widget>[
                  _MenuTab(state: state, restaurant: restaurant),
                  ReviewsTab(
                    reviews: detail.reviews,
                    summary: detail.ratingSummary,
                  ),
                  _InfoTab(restaurant: restaurant),
                ],
              ),
            ),
            bottomNavigationBar: _CartBar(restaurantId: restaurant.id),
          ),
        );
      },
    );
  }

  void _toggleFavourite(BuildContext context) {
    final User? user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    context.read<RestaurantBloc>().add(
          RestaurantFavouriteToggled(
            userId: user.id,
            restaurantId: restaurantId,
          ),
        );
  }
}

class _MenuTab extends StatelessWidget {
  const _MenuTab({required this.state, required this.restaurant});

  final RestaurantState state;
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final Map<FoodCategory, List<FoodItem>> sections = state.visibleSections;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        AppSpacing.lg,
        context.gutter,
        AppSpacing.huge * 2,
      ),
      children: <Widget>[
        ContentContainer(
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                onChanged: (String value) => context
                    .read<RestaurantBloc>()
                    .add(RestaurantMenuFiltered(value)),
                decoration: const InputDecoration(
                  hintText: 'Search this menu',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (sections.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.huge),
                  child: EmptyView(
                    title: 'Nothing on the menu matches',
                    message: 'Try a different word, or clear the search.',
                    icon: Icons.restaurant_menu_rounded,
                  ),
                )
              else
                for (final MapEntry<FoodCategory, List<FoodItem>> entry
                    in sections.entries) ...<Widget>[
                  _SectionHeading(category: entry.key, count: entry.value.length),
                  for (final FoodItem item in entry.value) ...<Widget>[
                    _MenuRow(item: item, restaurant: restaurant),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.category, required this.count});

  final FoodCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Text(category.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Text(category.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// A menu row whose trailing control switches between "Add" and a stepper,
/// driven by what is already in the basket.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.restaurant});

  final FoodItem item;
  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (CartState a, CartState b) =>
          a.quantityOf(item.id) != b.quantityOf(item.id),
      builder: (BuildContext context, CartState cart) {
        final int quantity = cart.quantityOf(item.id);

        return DishListTile(
          item: item,
          onTap: () => AddToCartSheet.show(
            context,
            item: item,
            restaurant: restaurant,
          ),
          trailing: quantity == 0
              ? _AddButton(
                  onPressed: () => AddToCartSheet.show(
                    context,
                    item: item,
                    restaurant: restaurant,
                  ),
                )
              : QuantityStepper(
                  quantity: quantity,
                  compact: true,
                  min: 0,
                  onIncrement: () => context.read<CartBloc>().add(
                        CartItemAdded(item: item, restaurant: restaurant),
                      ),
                  onDecrement: () => _decrement(context, cart, quantity),
                ),
        );
      },
    );
  }

  void _decrement(BuildContext context, CartState cart, int quantity) {
    // Find the specific line so notes-carrying duplicates are handled.
    final String lineId = cart.cart.lines
        .firstWhere((dynamic l) => l.item.id == item.id)
        .lineId;
    context
        .read<CartBloc>()
        .add(CartQuantityChanged(lineId: lineId, quantity: quantity - 1));
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(78, 32),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: const Text('Add'),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: AppCard(
        child: Row(
          children: <Widget>[
            _Metric(
              value: Formatters.rating(restaurant.rating),
              label: '${Formatters.compactCount(restaurant.reviewCount)} reviews',
              icon: Icons.star_rounded,
              iconColor: AppColors.accentAmber,
            ),
            _divider(theme),
            _Metric(
              value: Formatters.etaRange(
                restaurant.etaMinMinutes,
                restaurant.etaMaxMinutes,
              ),
              label: 'Delivery time',
              icon: Icons.schedule_rounded,
            ),
            _divider(theme),
            _Metric(
              value: restaurant.hasFreeDelivery
                  ? 'Free'
                  : Formatters.currencyCompact(restaurant.deliveryFeeMyr),
              label: 'Delivery fee',
              icon: Icons.local_shipping_outlined,
              valueColor:
                  restaurant.hasFreeDelivery ? AppColors.primary : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(ThemeData theme) => Container(
        height: 34,
        width: 1,
        color: theme.colorScheme.outlineVariant,
      );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
    this.valueColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 15,
                color: iconColor ?? theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: valueColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(context.gutter),
      children: <Widget>[
        ContentContainer(
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('About', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(restaurant.description, style: theme.textTheme.bodyMedium),
              const AppDivider(),
              _InfoRow(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: restaurant.address.formatted,
              ),
              _InfoRow(
                icon: Icons.schedule_rounded,
                title: 'Opening hours',
                value:
                    'Daily, ${restaurant.openingTime} - ${restaurant.closingTime}',
              ),
              if (restaurant.phone != null)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: restaurant.phone!,
                ),
              _InfoRow(
                icon: Icons.payments_outlined,
                title: 'Minimum order',
                value: Formatters.currency(restaurant.minOrderMyr),
              ),
              const AppDivider(),
              Text('Tags', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (final String cuisine in restaurant.cuisines)
                    InfoPill(label: cuisine, color: AppColors.primary, filled: true),
                  for (final String tag in restaurant.tags)
                    InfoPill(label: tag),
                ],
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky "view cart" bar shown only when this restaurant's basket has items.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (BuildContext context, CartState state) {
        if (state.cart.isEmpty || state.cart.restaurantId != restaurantId) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: () => context.push('/cart'),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md + 2,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '${state.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'View cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.currency(state.cart.subtotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar, this.background);

  final TabBar tabBar;
  final Color background;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      ColoredBox(color: background, child: tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar || oldDelegate.background != background;
}

class _RestaurantSkeleton extends StatelessWidget {
  const _RestaurantSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: EdgeInsets.all(context.gutter),
        children: <Widget>[
          const AppShimmer(
            child: SkeletonBox(height: 180, radius: AppRadius.lg),
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppShimmer(child: SkeletonBox(width: 220, height: 22)),
          const SizedBox(height: AppSpacing.sm),
          const AppShimmer(child: SkeletonBox(width: 160, height: 14)),
          const SizedBox(height: AppSpacing.xxl),
          for (int i = 0; i < 4; i++) ...<Widget>[
            const ListTileSkeleton(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}
