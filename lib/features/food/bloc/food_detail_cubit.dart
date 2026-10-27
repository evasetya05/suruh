import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/repositories/catalog_repository.dart';
import '../../../domain/usecases/catalog_usecases.dart';

part 'food_detail_state.dart';

/// Loads a dish plus the restaurant it belongs to.
///
/// A cubit rather than a bloc: this screen has exactly one action (load), so
/// event classes would be ceremony without benefit.
class FoodDetailCubit extends Cubit<FoodDetailState> {
  FoodDetailCubit({
    required GetFoodDetail getFoodDetail,
    required CatalogRepository catalog,
  })  : _getFoodDetail = getFoodDetail,
        _catalog = catalog,
        super(const FoodDetailState());

  final GetFoodDetail _getFoodDetail;
  final CatalogRepository _catalog;

  Future<void> load(String foodItemId) async {
    emit(state.copyWith(status: FoodDetailStatus.loading));

    final Result<FoodDetail> result = await _getFoodDetail(foodItemId);
    if (result.failureOrNull case final Failure failure) {
      emit(
        state.copyWith(
          status: FoodDetailStatus.failure,
          errorMessage: failure.message,
        ),
      );
      return;
    }

    final FoodDetail detail = result.valueOrNull!;

    // The restaurant is needed to add to the cart (delivery fee, minimum order,
    // open/closed), so it is fetched here rather than pushed through the route.
    final Result<Restaurant> restaurant =
        await _catalog.getRestaurantById(detail.item.restaurantId);

    emit(
      state.copyWith(
        status: FoodDetailStatus.success,
        detail: detail,
        restaurant: restaurant.valueOrNull,
        clearError: true,
      ),
    );
  }
}
