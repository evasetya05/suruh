import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/food_category.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/usecases/catalog_usecases.dart';
import '../../../domain/usecases/user_usecases.dart';

part 'restaurant_event.dart';
part 'restaurant_state.dart';

/// Restaurant page: details, grouped menu, reviews and the favourite toggle.
class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  RestaurantBloc({
    required GetRestaurantDetail getDetail,
    required ToggleFavourite toggleFavourite,
  })  : _getDetail = getDetail,
        _toggleFavourite = toggleFavourite,
        super(const RestaurantState()) {
    on<RestaurantRequested>(_onRequested);
    on<RestaurantSectionSelected>(_onSectionSelected);
    on<RestaurantFavouriteToggled>(_onFavouriteToggled);
    on<RestaurantMenuFiltered>(_onMenuFiltered);
  }

  final GetRestaurantDetail _getDetail;
  final ToggleFavourite _toggleFavourite;

  Future<void> _onRequested(
    RestaurantRequested event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RestaurantStatus.loading,
        isFavourite: event.isFavourite,
      ),
    );

    final Result<RestaurantDetail> result = await _getDetail(event.restaurantId);
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: RestaurantStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (RestaurantDetail detail) => emit(
        state.copyWith(
          status: RestaurantStatus.success,
          detail: detail,
          clearError: true,
        ),
      ),
    );
  }

  void _onSectionSelected(
    RestaurantSectionSelected event,
    Emitter<RestaurantState> emit,
  ) {
    emit(state.copyWith(selectedSectionId: event.categoryId));
  }

  void _onMenuFiltered(
    RestaurantMenuFiltered event,
    Emitter<RestaurantState> emit,
  ) {
    emit(state.copyWith(menuQuery: event.query));
  }

  /// Optimistic: the heart flips immediately and reverts only if the write
  /// fails, because waiting on a round-trip for a favourite feels broken.
  Future<void> _onFavouriteToggled(
    RestaurantFavouriteToggled event,
    Emitter<RestaurantState> emit,
  ) async {
    final bool previous = state.isFavourite;
    emit(state.copyWith(isFavourite: !previous));

    final Result<Set<String>> result = await _toggleFavourite(
      ToggleFavouriteParams(
        userId: event.userId,
        restaurantId: event.restaurantId,
      ),
    );

    result.fold(
      (Failure failure) => emit(
        state.copyWith(isFavourite: previous, errorMessage: failure.message),
      ),
      (Set<String> favourites) => emit(
        state.copyWith(isFavourite: favourites.contains(event.restaurantId)),
      ),
    );
  }
}
