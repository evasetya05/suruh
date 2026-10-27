import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cubit/theme_cubit.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/food_category.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/catalog_usecases.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shared/widgets/category_tile.dart';
import '../../shared/widgets/dish_card.dart';
import '../../shared/widgets/promo_carousel.dart';
import '../../shared/widgets/restaurant_card.dart';
import '../bloc/home_bloc.dart';
import 'widgets/home_header.dart';

/// The customer landing screen.
///
/// Rails mirror the Grab food home: categories, promos, featured merchants,
/// popular dishes, offers, then the full nearby list.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) =>
          HomeBloc(getHomeFeed: sl<GetHomeFeed>())..add(const HomeRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _openCategory(BuildContext context, FoodCategory category) {
    context.push('${Routes.browse}?category=${category.id}&title=${category.name}');
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.select((AuthBloc b) => b.state.user);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(const HomeRefreshed());
          // Give the bloc a beat so the indicator does not snap away instantly.
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (BuildContext context, HomeState state) {
            if (state.status == HomeStatus.failure && !state.hasFeed) {
              return ListView(
                children: <Widget>[
                  SizedBox(height: context.screenHeight * 0.2),
                  ErrorView(
                    message: state.errorMessage ??
                        'We could not load the menu right now.',
                    onRetry: () =>
                        context.read<HomeBloc>().add(const HomeRequested()),
                  ),
                ],
              );
            }

            return CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: HomeHeader(
                    user: user,
                    onSearchTap: () => context.go(Routes.search),
                    onThemeToggle: () => context.read<ThemeCubit>().cycle(),
                  ),
                ),
                if (state.isLoading)
                  const SliverToBoxAdapter(child: _HomeSkeleton())
                else
                  ..._buildFeed(context, state.feed!),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.huge),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildFeed(BuildContext context, HomeFeed feed) {
    return <Widget>[
      // --- Categories --------------------------------------------------------
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: ContentContainer(
            padded: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.gutter),
                  child: const SectionHeader(
                    title: 'What are you craving?',
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  ),
                ),
                CategoryStrip(
                  categories: feed.categories,
                  padding: EdgeInsets.symmetric(horizontal: context.gutter),
                  onSelected: (FoodCategory c) => _openCategory(context, c),
                ),
              ],
            ),
          ),
        ),
      ),

      // --- Promotions --------------------------------------------------------
      if (feed.promos.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ContentContainer(
              padded: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.gutter - AppSpacing.xs,
                ),
                child: PromoCarousel(promos: feed.promos),
              ),
            ),
          ),
        ),

      // --- Featured ----------------------------------------------------------
      _rail(
        context,
        title: 'Featured this week',
        subtitle: 'Hand-picked kitchens running an offer',
        onSeeAll: () => context.push('${Routes.browse}?title=Featured'),
        // Tall enough for the card's image, two text lines and both meta rows
        // with headroom for the app's maximum text scale.
        height: 296,
        itemCount: feed.featured.length,
        itemBuilder: (BuildContext context, int i) =>
            RestaurantCard(restaurant: feed.featured[i], width: 264),
      ),

      // --- Popular dishes ----------------------------------------------------
      _rail(
        context,
        title: 'Popular right now',
        subtitle: 'What people are ordering today',
        height: 262,
        itemCount: feed.popularDishes.length,
        itemBuilder: (BuildContext context, int i) =>
            DishCard(item: feed.popularDishes[i]),
      ),

      // --- Offers ------------------------------------------------------------
      if (feed.offers.isNotEmpty)
        _rail(
          context,
          title: 'Deals under RM 25',
          subtitle: 'Discounted dishes, while stocks last',
          height: 262,
          itemCount: feed.offers.length,
          itemBuilder: (BuildContext context, int i) =>
              DishCard(item: feed.offers[i]),
        ),

      // --- All restaurants ---------------------------------------------------
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: ContentContainer(
            child: SectionHeader(
              title: 'All restaurants near you',
              subtitle: '${feed.nearby.length} places delivering to Bukit Bintang',
              actionLabel: 'Filter',
              onAction: () => context.push(Routes.browse),
            ),
          ),
        ),
      ),
      _restaurantGrid(context, feed.nearby),
    ];
  }

  /// Section header plus a horizontally scrolling rail.
  Widget _rail(
    BuildContext context, {
    required String title,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required double height,
    String? subtitle,
    VoidCallback? onSeeAll,
  }) {
    if (itemCount == 0) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: ContentContainer(
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.gutter),
                child: SectionHeader(
                  title: title,
                  subtitle: subtitle,
                  actionLabel: onSeeAll == null ? null : 'See all',
                  onAction: onSeeAll,
                ),
              ),
              SizedBox(
                height: height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: context.gutter),
                  itemCount: itemCount,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: itemBuilder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One column on phones, a grid on tablet and desktop.
  Widget _restaurantGrid(BuildContext context, List<Restaurant> restaurants) {
    if (restaurants.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyView(
          title: 'No restaurants nearby',
          message: 'Try widening your delivery area.',
          icon: Icons.storefront_outlined,
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: context.gutter),
      sliver: SliverToBoxAdapter(
        child: ContentContainer(
          padded: false,
          child: context.isMobile
              ? Column(
                  children: <Widget>[
                    for (final Restaurant r in restaurants) ...<Widget>[
                      RestaurantListTile(restaurant: r),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.gridColumns,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: restaurants.length,
                  itemBuilder: (BuildContext context, int i) =>
                      RestaurantCard(restaurant: restaurants[i]),
                ),
        ),
      ),
    );
  }
}

/// Skeleton mirroring the real feed layout so the transition is not jarring.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ContentContainer(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppShimmer(child: SkeletonBox(width: 180, height: 20)),
            const SizedBox(height: AppSpacing.lg),
            // Scrollable so the fixed-width tiles cannot overflow on a narrow
            // phone the way a plain Row would.
            SizedBox(
              height: 80,
              child: AppShimmer(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: Column(
                      children: <Widget>[
                        SkeletonBox(
                          height: 56,
                          width: 56,
                          radius: AppRadius.lg,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        SkeletonBox(height: 10, width: 44),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppShimmer(
              child: SkeletonBox(
                height: 132,
                radius: AppRadius.lg,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppShimmer(child: SkeletonBox(width: 200, height: 20)),
            const SizedBox(height: AppSpacing.lg),
            const HorizontalSkeletonRow(itemWidth: 264),
            const SizedBox(height: AppSpacing.xxl),
            const AppShimmer(child: SkeletonBox(width: 160, height: 20)),
            const SizedBox(height: AppSpacing.lg),
            for (int i = 0; i < 3; i++) ...<Widget>[
              const ListTileSkeleton(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }
}
