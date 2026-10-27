part of 'restaurant_bloc.dart';

sealed class RestaurantEvent extends Equatable {
  const RestaurantEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class RestaurantRequested extends RestaurantEvent {
  const RestaurantRequested({
    required this.restaurantId,
    this.isFavourite = false,
  });

  final String restaurantId;

  /// Seeded from the signed-in user so the heart renders correctly on the very
  /// first frame instead of flickering.
  final bool isFavourite;

  @override
  List<Object?> get props => <Object?>[restaurantId, isFavourite];
}

class RestaurantSectionSelected extends RestaurantEvent {
  const RestaurantSectionSelected(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

class RestaurantMenuFiltered extends RestaurantEvent {
  const RestaurantMenuFiltered(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

class RestaurantFavouriteToggled extends RestaurantEvent {
  const RestaurantFavouriteToggled({
    required this.userId,
    required this.restaurantId,
  });

  final String userId;
  final String restaurantId;

  @override
  List<Object?> get props => <Object?>[userId, restaurantId];
}
