import '../../core/utils/result.dart';
import '../entities/food_category.dart';
import '../entities/food_item.dart';
import '../entities/promo.dart';
import '../entities/restaurant.dart';

/// How a restaurant list is ordered.
enum RestaurantSort {
  recommended('Recommended'),
  rating('Top rated'),
  deliveryTime('Fastest delivery'),
  deliveryFee('Lowest delivery fee'),
  distance('Nearest');

  const RestaurantSort(this.label);
  final String label;
}

/// Filter criteria applied to a restaurant query.
class RestaurantFilter {
  const RestaurantFilter({
    this.categoryId,
    this.query,
    this.sort = RestaurantSort.recommended,
    this.freeDeliveryOnly = false,
    this.openNowOnly = false,
    this.minRating,
    this.maxPriceLevel,
  });

  final String? categoryId;
  final String? query;
  final RestaurantSort sort;
  final bool freeDeliveryOnly;
  final bool openNowOnly;
  final double? minRating;
  final int? maxPriceLevel;

  bool get hasActiveFilters =>
      freeDeliveryOnly ||
      openNowOnly ||
      minRating != null ||
      maxPriceLevel != null ||
      categoryId != null;

  int get activeFilterCount => <bool>[
        freeDeliveryOnly,
        openNowOnly,
        minRating != null,
        maxPriceLevel != null,
      ].where((bool active) => active).length;

  RestaurantFilter copyWith({
    String? categoryId,
    String? query,
    RestaurantSort? sort,
    bool? freeDeliveryOnly,
    bool? openNowOnly,
    double? minRating,
    int? maxPriceLevel,
    bool clearCategory = false,
    bool clearQuery = false,
    bool clearMinRating = false,
    bool clearMaxPriceLevel = false,
  }) {
    return RestaurantFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      query: clearQuery ? null : (query ?? this.query),
      sort: sort ?? this.sort,
      freeDeliveryOnly: freeDeliveryOnly ?? this.freeDeliveryOnly,
      openNowOnly: openNowOnly ?? this.openNowOnly,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      maxPriceLevel:
          clearMaxPriceLevel ? null : (maxPriceLevel ?? this.maxPriceLevel),
    );
  }
}

/// Everything a customer browses: restaurants, dishes, categories, promos.
abstract interface class CatalogRepository {
  Future<Result<List<FoodCategory>>> getCategories();

  Future<Result<List<Restaurant>>> getRestaurants([RestaurantFilter filter]);

  Future<Result<Restaurant>> getRestaurantById(String id);

  /// Restaurants flagged as featured on the home screen.
  Future<Result<List<Restaurant>>> getFeaturedRestaurants();

  Future<Result<List<FoodItem>>> getMenuForRestaurant(String restaurantId);

  Future<Result<FoodItem>> getFoodItemById(String id);

  /// Best-selling dishes across all restaurants.
  Future<Result<List<FoodItem>>> getPopularDishes({int limit = 10});

  /// Dishes with an active discount.
  Future<Result<List<FoodItem>>> getDiscountedDishes({int limit = 10});

  Future<Result<List<Promo>>> getPromos();

  /// Free-text search across restaurant names, cuisines and dish names.
  Future<Result<SearchResults>> search(String query);

  /// Forces a catalogue refresh from the remote source into the local cache.
  Future<Result<void>> refresh();
}

/// Combined search hits so one query populates both result tabs.
class SearchResults {
  const SearchResults({
    required this.restaurants,
    required this.dishes,
    required this.query,
  });

  final List<Restaurant> restaurants;
  final List<FoodItem> dishes;
  final String query;

  bool get isEmpty => restaurants.isEmpty && dishes.isEmpty;
  int get totalCount => restaurants.length + dishes.length;
}
