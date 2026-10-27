part of 'food_detail_cubit.dart';

enum FoodDetailStatus { initial, loading, success, failure }

class FoodDetailState extends Equatable {
  const FoodDetailState({
    this.status = FoodDetailStatus.initial,
    this.detail,
    this.restaurant,
    this.errorMessage,
  });

  final FoodDetailStatus status;
  final FoodDetail? detail;

  /// Null while loading, or if the parent restaurant could not be resolved -
  /// in which case the add-to-cart action is disabled rather than crashing.
  final Restaurant? restaurant;
  final String? errorMessage;

  bool get isLoading =>
      status == FoodDetailStatus.loading || status == FoodDetailStatus.initial;

  bool get canAddToCart =>
      restaurant != null &&
      restaurant!.isOpen &&
      (detail?.item.isAvailable ?? false);

  List<Review> get reviews => detail?.reviews ?? const <Review>[];

  FoodDetailState copyWith({
    FoodDetailStatus? status,
    FoodDetail? detail,
    Restaurant? restaurant,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FoodDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      restaurant: restaurant ?? this.restaurant,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, detail, restaurant, errorMessage];
}
