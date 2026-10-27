import 'package:equatable/equatable.dart';

import '../../core/usecase/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/food_category.dart';
import '../entities/food_item.dart';
import '../entities/promo.dart';
import '../entities/restaurant.dart';
import '../entities/review.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/review_repository.dart';

/// Everything the home screen renders, fetched as one unit.
class HomeFeed extends Equatable {
  const HomeFeed({
    required this.categories,
    required this.featured,
    required this.nearby,
    required this.popularDishes,
    required this.offers,
    required this.promos,
  });

  final List<FoodCategory> categories;
  final List<Restaurant> featured;
  final List<Restaurant> nearby;
  final List<FoodItem> popularDishes;
  final List<FoodItem> offers;
  final List<Promo> promos;

  @override
  List<Object?> get props =>
      <Object?>[categories, featured, nearby, popularDishes, offers, promos];
}

/// Loads the six home rails concurrently and fails fast if any of them fail.
///
/// This is the reason use cases exist in this codebase: the bloc asks for "the
/// home feed" and stays unaware that it is six repository calls fanned out in
/// parallel.
class GetHomeFeed extends UseCase<HomeFeed, NoParams> {
  const GetHomeFeed(this._catalog);

  final CatalogRepository _catalog;

  @override
  Future<Result<HomeFeed>> call(NoParams params) async {
    final List<Result<Object>> results = await Future.wait<Result<Object>>(
      <Future<Result<Object>>>[
        _catalog.getCategories(),
        _catalog.getFeaturedRestaurants(),
        _catalog.getRestaurants(),
        _catalog.getPopularDishes(),
        _catalog.getDiscountedDishes(),
        _catalog.getPromos(),
      ],
    );

    for (final Result<Object> result in results) {
      if (result.failureOrNull case final failure?) {
        return Result<HomeFeed>.failure(failure);
      }
    }

    return Result<HomeFeed>.success(
      HomeFeed(
        categories: results[0].valueOrNull! as List<FoodCategory>,
        featured: results[1].valueOrNull! as List<Restaurant>,
        nearby: results[2].valueOrNull! as List<Restaurant>,
        popularDishes: results[3].valueOrNull! as List<FoodItem>,
        offers: results[4].valueOrNull! as List<FoodItem>,
        promos: results[5].valueOrNull! as List<Promo>,
      ),
    );
  }
}

/// A restaurant with its menu grouped by section, plus review data.
class RestaurantDetail extends Equatable {
  const RestaurantDetail({
    required this.restaurant,
    required this.menu,
    required this.menuSections,
    required this.reviews,
    required this.ratingSummary,
  });

  final Restaurant restaurant;
  final List<FoodItem> menu;

  /// Category id to dishes, in menu order.
  final Map<FoodCategory, List<FoodItem>> menuSections;
  final List<Review> reviews;
  final RatingSummary ratingSummary;

  List<FoodItem> get popularItems =>
      menu.where((FoodItem i) => i.isPopular).toList(growable: false);

  @override
  List<Object?> get props =>
      <Object?>[restaurant, menu, reviews, ratingSummary];
}

class GetRestaurantDetail extends UseCase<RestaurantDetail, String> {
  const GetRestaurantDetail(this._catalog, this._reviews);

  final CatalogRepository _catalog;
  final ReviewRepository _reviews;

  @override
  Future<Result<RestaurantDetail>> call(String restaurantId) async {
    final Result<Restaurant> restaurantResult =
        await _catalog.getRestaurantById(restaurantId);
    if (restaurantResult.failureOrNull case final failure?) {
      return Result<RestaurantDetail>.failure(failure);
    }

    final List<Object> parts = await Future.wait<Object>(<Future<Object>>[
      _catalog.getMenuForRestaurant(restaurantId),
      _reviews.getReviewsForRestaurant(restaurantId),
      _catalog.getCategories(),
    ]);

    final Result<List<FoodItem>> menuResult =
        parts[0] as Result<List<FoodItem>>;
    if (menuResult.failureOrNull case final failure?) {
      return Result<RestaurantDetail>.failure(failure);
    }

    final Result<List<Review>> reviewsResult = parts[1] as Result<List<Review>>;
    final Result<List<FoodCategory>> categoriesResult =
        parts[2] as Result<List<FoodCategory>>;

    final List<FoodItem> menu = menuResult.valueOrNull!;
    final List<Review> reviews =
        reviewsResult.valueOrNull ?? const <Review>[];
    final List<FoodCategory> categories =
        categoriesResult.valueOrNull ?? const <FoodCategory>[];

    // Group the menu into sections, keeping the catalogue's category order and
    // dropping sections this restaurant has no dishes for.
    final Map<FoodCategory, List<FoodItem>> sections =
        <FoodCategory, List<FoodItem>>{};
    for (final FoodCategory category in categories) {
      final List<FoodItem> items = menu
          .where((FoodItem item) => item.categoryId == category.id)
          .toList(growable: false);
      if (items.isNotEmpty) sections[category] = items;
    }

    return Result<RestaurantDetail>.success(
      RestaurantDetail(
        restaurant: restaurantResult.valueOrNull!,
        menu: menu,
        menuSections: sections,
        reviews: reviews,
        ratingSummary: RatingSummary.fromReviews(reviews),
      ),
    );
  }
}

class GetFilteredRestaurants
    extends UseCase<List<Restaurant>, RestaurantFilter> {
  const GetFilteredRestaurants(this._catalog);

  final CatalogRepository _catalog;

  @override
  Future<Result<List<Restaurant>>> call(RestaurantFilter params) =>
      _catalog.getRestaurants(params);
}

class SearchCatalog extends UseCase<SearchResults, String> {
  const SearchCatalog(this._catalog);

  final CatalogRepository _catalog;

  @override
  Future<Result<SearchResults>> call(String params) =>
      _catalog.search(params.trim());
}

/// Dish detail plus the dish-specific reviews shown beneath it.
class FoodDetail extends Equatable {
  const FoodDetail({required this.item, required this.reviews});

  final FoodItem item;
  final List<Review> reviews;

  @override
  List<Object?> get props => <Object?>[item, reviews];
}

class GetFoodDetail extends UseCase<FoodDetail, String> {
  const GetFoodDetail(this._catalog, this._reviews);

  final CatalogRepository _catalog;
  final ReviewRepository _reviews;

  @override
  Future<Result<FoodDetail>> call(String foodItemId) async {
    final Result<FoodItem> itemResult = await _catalog.getFoodItemById(foodItemId);
    if (itemResult.failureOrNull case final failure?) {
      return Result<FoodDetail>.failure(failure);
    }
    final Result<List<Review>> reviews =
        await _reviews.getReviewsForFoodItem(foodItemId);
    return Result<FoodDetail>.success(
      FoodDetail(
        item: itemResult.valueOrNull!,
        reviews: reviews.valueOrNull ?? const <Review>[],
      ),
    );
  }
}

class RefreshCatalog extends UseCase<void, NoParams> {
  const RefreshCatalog(this._catalog);

  final CatalogRepository _catalog;

  @override
  Future<Result<void>> call(NoParams params) => _catalog.refresh();
}
