part of 'browse_bloc.dart';

enum BrowseStatus { initial, loading, success, failure }

class BrowseState extends Equatable {
  const BrowseState({
    this.status = BrowseStatus.initial,
    this.restaurants = const <Restaurant>[],
    this.categories = const <FoodCategory>[],
    this.filter = const RestaurantFilter(),
    this.errorMessage,
  });

  final BrowseStatus status;
  final List<Restaurant> restaurants;
  final List<FoodCategory> categories;
  final RestaurantFilter filter;
  final String? errorMessage;

  bool get isLoading =>
      status == BrowseStatus.loading || status == BrowseStatus.initial;

  bool get isEmpty =>
      status == BrowseStatus.success && restaurants.isEmpty;

  BrowseState copyWith({
    BrowseStatus? status,
    List<Restaurant>? restaurants,
    List<FoodCategory>? categories,
    RestaurantFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BrowseState(
      status: status ?? this.status,
      restaurants: restaurants ?? this.restaurants,
      categories: categories ?? this.categories,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        restaurants,
        categories,
        filter.categoryId,
        filter.sort,
        filter.freeDeliveryOnly,
        filter.openNowOnly,
        filter.minRating,
        filter.maxPriceLevel,
        errorMessage,
      ];
}
