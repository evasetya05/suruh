import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/service_locator.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/usecases/catalog_usecases.dart';
import '../../shared/widgets/dish_card.dart';
import '../../shared/widgets/restaurant_card.dart';
import '../bloc/search_bloc.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBloc>(
      create: (_) => SearchBloc(
        searchCatalog: sl<SearchCatalog>(),
        storage: sl<LocalStorage>(),
      ),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runQuery(String query) {
    _controller
      ..text = query
      ..selection = TextSelection.collapsed(offset: query.length);
    context.read<SearchBloc>().add(SearchQueryChanged(query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                AppSpacing.md,
                context.gutter,
                AppSpacing.sm,
              ),
              child: ContentContainer(
                padded: false,
                child: BlocBuilder<SearchBloc, SearchState>(
                  buildWhen: (SearchState a, SearchState b) =>
                      a.query != b.query || a.isSearching != b.isSearching,
                  builder: (BuildContext context, SearchState state) {
                    return TextField(
                      controller: _controller,
                      autofocus: false,
                      textInputAction: TextInputAction.search,
                      onChanged: (String value) => context
                          .read<SearchBloc>()
                          .add(SearchQueryChanged(value)),
                      decoration: InputDecoration(
                        hintText: 'Search restaurants or dishes',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: state.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                icon: state.isSearching
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _controller.clear();
                                  context
                                      .read<SearchBloc>()
                                      .add(const SearchCleared());
                                },
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (BuildContext context, SearchState state) =>
                    _SearchBody(state: state, onSuggestionTap: _runQuery),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.state, required this.onSuggestionTap});

  final SearchState state;
  final ValueChanged<String> onSuggestionTap;

  /// Shown before anyone has typed anything.
  static const List<String> _trending = <String>[
    'Nasi lemak',
    'Bubble tea',
    'Xiao long bao',
    'Burger',
    'Ramen',
    'Durian',
    'Roti canai',
    'Fried chicken',
  ];

  @override
  Widget build(BuildContext context) {
    if (state.isSearching && state.results == null) {
      return ListView.separated(
        padding: EdgeInsets.all(context.gutter),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xl),
        itemBuilder: (_, __) => const ListTileSkeleton(),
      );
    }

    if (state.status == SearchStatus.failure) {
      return ErrorView(
        message: state.errorMessage ?? 'Search is unavailable right now.',
        onRetry: () => context
            .read<SearchBloc>()
            .add(SearchQueryChanged(state.query)),
      );
    }

    if (state.status == SearchStatus.idle) {
      return _Suggestions(
        recent: state.recentQueries,
        trending: _trending,
        onTap: onSuggestionTap,
      );
    }

    if (state.hasNoResults) {
      return EmptyView(
        title: 'No matches for "${state.query.trim()}"',
        message: 'Check the spelling, or try a cuisine like "Thai" or "pizza".',
        icon: Icons.search_off_rounded,
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        AppSpacing.sm,
        context.gutter,
        AppSpacing.huge,
      ),
      children: <Widget>[
        ContentContainer(
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (state.restaurants.isNotEmpty) ...<Widget>[
                SectionHeader(
                  title: 'Restaurants',
                  subtitle: '${state.restaurants.length} found',
                ),
                for (final Restaurant r in state.restaurants) ...<Widget>[
                  RestaurantListTile(restaurant: r),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
              if (state.dishes.isNotEmpty) ...<Widget>[
                SectionHeader(
                  title: 'Dishes',
                  subtitle: '${state.dishes.length} found',
                ),
                for (final FoodItem dish in state.dishes) ...<Widget>[
                  DishListTile(item: dish, showRestaurant: true),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.recent,
    required this.trending,
    required this.onTap,
  });

  final List<String> recent;
  final List<String> trending;
  final ValueChanged<String> onTap;

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
              if (recent.isNotEmpty) ...<Widget>[
                const SectionHeader(title: 'Recent searches'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: recent
                      .map(
                        (String query) => InputChip(
                          label: Text(query),
                          avatar: const Icon(Icons.history_rounded, size: 16),
                          onPressed: () => onTap(query),
                          onDeleted: () => context
                              .read<SearchBloc>()
                              .add(SearchRecentRemoved(query)),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
              const SectionHeader(
                title: 'Trending in Kuala Lumpur',
                subtitle: 'What people are searching for today',
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: trending
                    .map(
                      (String query) => ActionChip(
                        label: Text(query),
                        avatar: const Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                        ),
                        onPressed: () => onTap(query),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Center(
                child: Text(
                  'Tip: you can search by ingredient too, like "prawn".',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
