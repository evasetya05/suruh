import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/service_locator.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/food_category.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/usecases/catalog_usecases.dart';
import '../../shared/widgets/category_tile.dart';
import '../../shared/widgets/restaurant_card.dart';
import '../bloc/browse_bloc.dart';
import 'widgets/filter_sheet.dart';

/// Filterable restaurant listing.
///
/// Reached from a category tile, the home "Filter" action, or a "See all" link.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({this.categoryId, this.title, super.key});

  final String? categoryId;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BrowseBloc>(
      create: (_) => BrowseBloc(
        getRestaurants: sl<GetFilteredRestaurants>(),
        getHomeFeed: sl<GetHomeFeed>(),
      )..add(BrowseStarted(categoryId: categoryId)),
      child: _BrowseView(title: title),
    );
  }
}

class _BrowseView extends StatelessWidget {
  const _BrowseView({this.title});

  final String? title;

  Future<void> _openFilters(BuildContext context) async {
    final BrowseBloc bloc = context.read<BrowseBloc>();
    final RestaurantFilter? updated = await showModalBottomSheet<RestaurantFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(initial: bloc.state.filter),
    );
    if (updated != null) bloc.add(BrowseFilterChanged(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrowseBloc, BrowseState>(
      builder: (BuildContext context, BrowseState state) {
        final int activeFilters = state.filter.activeFilterCount;

        return Scaffold(
          appBar: AppBar(
            title: Text(title ?? 'Restaurants'),
            actions: <Widget>[
              IconButton(
                onPressed: () => _openFilters(context),
                tooltip: 'Filter and sort',
                icon: Badge(
                  isLabelVisible: activeFilters > 0,
                  label: Text('$activeFilters'),
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          body: Column(
            children: <Widget>[
              if (state.categories.isNotEmpty)
                CategoryStrip(
                  categories: state.categories,
                  selectedId: state.filter.categoryId,
                  onSelected: (FoodCategory category) {
                    // Tapping the active category clears it, which is the
                    // behaviour people expect from a toggle-style chip.
                    final bool isActive =
                        state.filter.categoryId == category.id;
                    context.read<BrowseBloc>().add(
                          BrowseFilterChanged(
                            isActive
                                ? state.filter.copyWith(clearCategory: true)
                                : state.filter
                                    .copyWith(categoryId: category.id),
                          ),
                        );
                  },
                ),
              _SortRow(
                sort: state.filter.sort,
                resultCount: state.restaurants.length,
                isLoading: state.isLoading,
                onChanged: (RestaurantSort sort) => context
                    .read<BrowseBloc>()
                    .add(BrowseFilterChanged(state.filter.copyWith(sort: sort))),
              ),
              Expanded(child: _Results(state: state)),
            ],
          ),
        );
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state});

  final BrowseState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return ListView.separated(
        padding: EdgeInsets.all(context.gutter),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xl),
        itemBuilder: (_, __) => const ListTileSkeleton(),
      );
    }

    if (state.status == BrowseStatus.failure) {
      return ErrorView(
        message: state.errorMessage ?? 'Could not load restaurants.',
        onRetry: () =>
            context.read<BrowseBloc>().add(const BrowseStarted()),
      );
    }

    if (state.isEmpty) {
      return EmptyView(
        title: 'Nothing matches those filters',
        message: 'Try removing a filter or picking a different category.',
        icon: Icons.filter_alt_off_outlined,
        actionLabel: 'Clear filters',
        onAction: () =>
            context.read<BrowseBloc>().add(const BrowseFiltersCleared()),
      );
    }

    if (context.isMobile) {
      return ListView.separated(
        padding: EdgeInsets.all(context.gutter),
        itemCount: state.restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (BuildContext context, int i) =>
            RestaurantListTile(restaurant: state.restaurants[i]),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.gutter),
      child: ContentContainer(
        padded: false,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.gridColumns,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            childAspectRatio: 0.78,
          ),
          itemCount: state.restaurants.length,
          itemBuilder: (BuildContext context, int i) =>
              RestaurantCard(restaurant: state.restaurants[i]),
        ),
      ),
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.sort,
    required this.resultCount,
    required this.isLoading,
    required this.onChanged,
  });

  final RestaurantSort sort;
  final int resultCount;
  final bool isLoading;
  final ValueChanged<RestaurantSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        AppSpacing.sm,
        context.gutter,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Text(
            isLoading ? 'Loading...' : '$resultCount places',
            style: theme.textTheme.bodySmall,
          ),
          const Spacer(),
          PopupMenuButton<RestaurantSort>(
            initialValue: sort,
            onSelected: onChanged,
            tooltip: 'Sort',
            itemBuilder: (_) => RestaurantSort.values
                .map(
                  (RestaurantSort value) => PopupMenuItem<RestaurantSort>(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(growable: false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.swap_vert_rounded, size: 18),
                const SizedBox(width: 4),
                Text(sort.label, style: theme.textTheme.labelLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
