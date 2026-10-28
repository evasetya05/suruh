import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/cubit/theme_cubit.dart';
import '../../../app/di/service_locator.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
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
import 'widgets/custom_suruh_modal.dart';
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
      // --- Hero Quick Action: Suruh Apa Saja --------------------------------
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.gutter, AppSpacing.lg, context.gutter, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF00B14F), Color(0xFF007A34)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => CustomSuruhModal.show(context),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Text('⚡', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Ada Urusan? Suruh Kami!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Bisa suruh apa saja: antar, belanja, antre & lainnya.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'Suruh ✨',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

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
                    title: 'Layanan SURUH',
                    subtitle: 'Bisa suruh apa saja sesuai kebutuhanmu',
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  ),
                ),
                CategoryStrip(
                  categories: feed.categories,
                  padding: EdgeInsets.symmetric(horizontal: context.gutter),
                  onSelected: (FoodCategory c) {
                    if (c.id == 'bebas') {
                      CustomSuruhModal.show(context);
                    } else {
                      _openCategory(context, c);
                    }
                  },
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
        title: 'Mitra & Hub Layanan',
        subtitle: 'Penyedia jasa & toko terverifikasi di Pontianak',
        onSeeAll: () => context.push('${Routes.browse}?title=Mitra%20Layanan'),
        height: 296,
        itemCount: feed.featured.length,
        itemBuilder: (BuildContext context, int i) =>
            RestaurantCard(restaurant: feed.featured[i], width: 264),
      ),

      // --- Popular dishes ----------------------------------------------------
      _rail(
        context,
        title: 'Layanan Populer Minggu Ini',
        subtitle: 'Paling sering dipesan oleh warga Pontianak',
        height: 262,
        itemCount: feed.popularDishes.length,
        itemBuilder: (BuildContext context, int i) =>
            DishCard(item: feed.popularDishes[i]),
      ),

      // --- Offers ------------------------------------------------------------
      if (feed.offers.isNotEmpty)
        _rail(
          context,
          title: 'Tarif Hemat & Penawaran',
          subtitle: 'Biaya jasa transparan & terjangkau',
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
              title: 'Semua Mitra di Pontianak',
              subtitle: '${feed.nearby.length} mitra siap melayani seluruh kota',
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
