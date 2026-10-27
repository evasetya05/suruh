import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/food_category.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/usecases/catalog_usecases.dart';

part 'browse_event.dart';
part 'browse_state.dart';

/// Filtered restaurant listing behind the category tiles and the "Filter"
/// action on the home screen.
class BrowseBloc extends Bloc<BrowseEvent, BrowseState> {
  BrowseBloc({
    required GetFilteredRestaurants getRestaurants,
    required GetHomeFeed getHomeFeed,
  })  : _getRestaurants = getRestaurants,
        _getHomeFeed = getHomeFeed,
        super(const BrowseState()) {
    on<BrowseStarted>(_onStarted);
    on<BrowseFilterChanged>(_onFilterChanged);
    on<BrowseFiltersCleared>(_onFiltersCleared);
  }

  final GetFilteredRestaurants _getRestaurants;
  final GetHomeFeed _getHomeFeed;

  Future<void> _onStarted(
    BrowseStarted event,
    Emitter<BrowseState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BrowseStatus.loading,
        filter: RestaurantFilter(categoryId: event.categoryId),
      ),
    );

    // The category strip is part of this screen's chrome, so it is fetched once
    // alongside the first page of results.
    final Result<HomeFeed> feed = await _getHomeFeed(const NoParams());
    emit(
      state.copyWith(
        categories: feed.valueOrNull?.categories ?? const <FoodCategory>[],
      ),
    );

    await _fetch(emit);
  }

  Future<void> _onFilterChanged(
    BrowseFilterChanged event,
    Emitter<BrowseState> emit,
  ) async {
    emit(state.copyWith(status: BrowseStatus.loading, filter: event.filter));
    await _fetch(emit);
  }

  Future<void> _onFiltersCleared(
    BrowseFiltersCleared event,
    Emitter<BrowseState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BrowseStatus.loading,
        filter: const RestaurantFilter(),
      ),
    );
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<BrowseState> emit) async {
    final Result<List<Restaurant>> result = await _getRestaurants(state.filter);
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: BrowseStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (List<Restaurant> restaurants) => emit(
        state.copyWith(
          status: BrowseStatus.success,
          restaurants: restaurants,
          clearError: true,
        ),
      ),
    );
  }
}
