import '../../core/error/exceptions.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/local/demo_data_source.dart';
import '../models/food_item_model.dart';
import '../models/restaurant_model.dart';

/// Cache-aware catalogue.
///
/// Reads follow an offline-first policy: try the remote source, write what came
/// back to [LocalStorage], and fall back to that cache when the device is
/// offline or the call throws. That is what lets the app open and browse with
/// no connection.
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({
    required DemoDataSource remote,
    required LocalStorage storage,
    required ConnectivityService connectivity,
  })  : _remote = remote,
        _storage = storage,
        _connectivity = connectivity;

  final DemoDataSource _remote;
  final LocalStorage _storage;
  final ConnectivityService _connectivity;

  @override
  Future<Result<List<FoodCategory>>> getCategories() =>
      guard<List<FoodCategory>>(() => _remote.getCategories());

  @override
  Future<Result<List<Restaurant>>> getRestaurants([
    RestaurantFilter filter = const RestaurantFilter(),
  ]) {
    return guard<List<Restaurant>>(() async {
      final List<RestaurantModel> all = await _loadRestaurants();
      // The menu is needed to answer "does this restaurant serve desserts?",
      // so it is loaded up front rather than read from a possibly-cold cache.
      final List<FoodItemModel> foods =
          filter.categoryId == null ? const <FoodItemModel>[] : await _loadFoods();
      return _applyFilter(all, filter, foods);
    });
  }

  @override
  Future<Result<Restaurant>> getRestaurantById(String id) {
    return guard<Restaurant>(() async {
      try {
        return await _remote.getRestaurantById(id);
      } on NotFoundException {
        rethrow;
      } on Object {
        final RestaurantModel? cached = _cachedRestaurants()
            .where((RestaurantModel r) => r.id == id)
            .firstOrNull;
        if (cached == null) {
          throw const NetworkException('Restaurant unavailable offline.');
        }
        return cached;
      }
    });
  }

  @override
  Future<Result<List<Restaurant>>> getFeaturedRestaurants() {
    return guard<List<Restaurant>>(() async {
      final List<RestaurantModel> all = await _loadRestaurants();
      final List<RestaurantModel> promoted = all
          .where((RestaurantModel r) => r.isPromoted)
          .toList(growable: false);
      // Fall back to top-rated when nothing is flagged, so the rail is never
      // empty.
      if (promoted.isNotEmpty) return promoted;
      final List<RestaurantModel> sorted = List<RestaurantModel>.of(all)
        ..sort((RestaurantModel a, RestaurantModel b) =>
            b.rating.compareTo(a.rating));
      return sorted.take(6).toList(growable: false);
    });
  }

  @override
  Future<Result<List<FoodItem>>> getMenuForRestaurant(String restaurantId) {
    return guard<List<FoodItem>>(() async {
      try {
        return await _remote.getMenu(restaurantId);
      } on Object {
        return _cachedFoods()
            .where((FoodItemModel f) => f.restaurantId == restaurantId)
            .toList(growable: false);
      }
    });
  }

  @override
  Future<Result<FoodItem>> getFoodItemById(String id) {
    return guard<FoodItem>(() async {
      try {
        return await _remote.getFoodById(id);
      } on NotFoundException {
        rethrow;
      } on Object {
        final FoodItemModel? cached =
            _cachedFoods().where((FoodItemModel f) => f.id == id).firstOrNull;
        if (cached == null) {
          throw const NetworkException('Dish unavailable offline.');
        }
        return cached;
      }
    });
  }

  @override
  Future<Result<List<FoodItem>>> getPopularDishes({int limit = 10}) {
    return guard<List<FoodItem>>(() async {
      final List<FoodItemModel> all = await _loadFoods();
      final List<FoodItemModel> popular = all
          .where((FoodItemModel f) => f.isPopular && f.isAvailable)
          .toList(growable: true)
        ..sort((FoodItemModel a, FoodItemModel b) {
          final int byRating = b.rating.compareTo(a.rating);
          return byRating != 0
              ? byRating
              : b.reviewCount.compareTo(a.reviewCount);
        });
      return popular.take(limit).toList(growable: false);
    });
  }

  @override
  Future<Result<List<FoodItem>>> getDiscountedDishes({int limit = 10}) {
    return guard<List<FoodItem>>(() async {
      final List<FoodItemModel> all = await _loadFoods();
      final List<FoodItemModel> offers = all
          .where((FoodItemModel f) => f.isOnOffer && f.isAvailable)
          .toList(growable: true)
        ..sort((FoodItemModel a, FoodItemModel b) =>
            b.discountPercent.compareTo(a.discountPercent));
      return offers.take(limit).toList(growable: false);
    });
  }

  @override
  Future<Result<List<Promo>>> getPromos() =>
      guard<List<Promo>>(() => _remote.getPromos());

  @override
  Future<Result<SearchResults>> search(String query) {
    return guard<SearchResults>(() async {
      final String needle = query.trim().toLowerCase();
      if (needle.isEmpty) {
        return SearchResults(
          restaurants: const <Restaurant>[],
          dishes: const <FoodItem>[],
          query: query,
        );
      }

      final List<RestaurantModel> restaurants = await _loadRestaurants();
      final List<FoodItemModel> foods = await _loadFoods();

      final List<Restaurant> restaurantHits = restaurants
          .where(
            (RestaurantModel r) =>
                r.name.toLowerCase().contains(needle) ||
                r.cuisines.any(
                  (String c) => c.toLowerCase().contains(needle),
                ) ||
                r.tags.any((String t) => t.toLowerCase().contains(needle)),
          )
          .toList(growable: false);

      final List<FoodItem> dishHits = foods
          .where(
            (FoodItemModel f) =>
                f.name.toLowerCase().contains(needle) ||
                f.description.toLowerCase().contains(needle) ||
                f.ingredients.any(
                  (String i) => i.toLowerCase().contains(needle),
                ),
          )
          .toList(growable: false);

      return SearchResults(
        restaurants: restaurantHits,
        dishes: dishHits,
        query: query,
      );
    });
  }

  @override
  Future<Result<void>> refresh() {
    return guard<void>(() async {
      final List<RestaurantModel> restaurants = await _remote.getRestaurants();
      final List<FoodItemModel> foods = await _remote.getFoods();
      await _writeCache(restaurants, foods);
    });
  }

  // --- Cache plumbing -------------------------------------------------------

  /// Remote-first with a cache fallback.
  Future<List<RestaurantModel>> _loadRestaurants() async {
    if (!await _connectivity.isOnline) {
      final List<RestaurantModel> cached = _cachedRestaurants();
      if (cached.isNotEmpty) return cached;
    }
    try {
      final List<RestaurantModel> fresh = await _remote.getRestaurants();
      await _storage.writeJsonList(
        LocalStorage.kRestaurants,
        fresh.map((RestaurantModel r) => r.toJson()).toList(growable: false),
      );
      await _storage.stampCache();
      return fresh;
    } on Object {
      final List<RestaurantModel> cached = _cachedRestaurants();
      if (cached.isEmpty) {
        throw const NetworkException(
          'No connection and nothing saved yet. Connect and try again.',
        );
      }
      return cached;
    }
  }

  Future<List<FoodItemModel>> _loadFoods() async {
    if (!await _connectivity.isOnline) {
      final List<FoodItemModel> cached = _cachedFoods();
      if (cached.isNotEmpty) return cached;
    }
    try {
      final List<FoodItemModel> fresh = await _remote.getFoods();
      await _storage.writeJsonList(
        LocalStorage.kFoods,
        fresh.map((FoodItemModel f) => f.toJson()).toList(growable: false),
      );
      return fresh;
    } on Object {
      final List<FoodItemModel> cached = _cachedFoods();
      if (cached.isEmpty) {
        throw const NetworkException(
          'No connection and nothing saved yet. Connect and try again.',
        );
      }
      return cached;
    }
  }

  Future<void> _writeCache(
    List<RestaurantModel> restaurants,
    List<FoodItemModel> foods,
  ) async {
    await _storage.writeJsonList(
      LocalStorage.kRestaurants,
      restaurants.map((RestaurantModel r) => r.toJson()).toList(growable: false),
    );
    await _storage.writeJsonList(
      LocalStorage.kFoods,
      foods.map((FoodItemModel f) => f.toJson()).toList(growable: false),
    );
    await _storage.stampCache();
  }

  List<RestaurantModel> _cachedRestaurants() {
    try {
      return _storage
          .readJsonList(LocalStorage.kRestaurants)
          .map(RestaurantModel.fromJson)
          .toList(growable: false);
    } on Object {
      return const <RestaurantModel>[];
    }
  }

  List<FoodItemModel> _cachedFoods() {
    try {
      return _storage
          .readJsonList(LocalStorage.kFoods)
          .map(FoodItemModel.fromJson)
          .toList(growable: false);
    } on Object {
      return const <FoodItemModel>[];
    }
  }

  // --- Filtering ------------------------------------------------------------

  /// Filtering and sorting happen client-side here because the demo catalogue
  /// is small. Against Firestore this maps to composite `where` clauses plus an
  /// `orderBy`; the contract stays identical.
  List<Restaurant> _applyFilter(
    List<RestaurantModel> source,
    RestaurantFilter filter,
    List<FoodItemModel> foods,
  ) {
    Iterable<RestaurantModel> result = source;

    if (filter.categoryId != null) {
      // A restaurant matches a category when its cuisine list matches (covering
      // "Chinese" as a cuisine) or when it serves at least one dish in it.
      final String category = filter.categoryId!.toLowerCase();
      final Set<String> restaurantIdsWithCategory = foods
          .where((FoodItemModel f) => f.categoryId == filter.categoryId)
          .map((FoodItemModel f) => f.restaurantId)
          .toSet();
      result = result.where(
        (RestaurantModel r) =>
            r.cuisines.any((String c) => c.toLowerCase() == category) ||
            restaurantIdsWithCategory.contains(r.id),
      );
    }

    if (filter.query != null && filter.query!.trim().isNotEmpty) {
      final String needle = filter.query!.toLowerCase();
      result = result.where(
        (RestaurantModel r) =>
            r.name.toLowerCase().contains(needle) ||
            r.cuisines.any((String c) => c.toLowerCase().contains(needle)),
      );
    }

    if (filter.freeDeliveryOnly) {
      result = result.where((RestaurantModel r) => r.hasFreeDelivery);
    }
    if (filter.openNowOnly) {
      result = result.where((RestaurantModel r) => r.isOpen);
    }
    if (filter.minRating != null) {
      result = result.where((RestaurantModel r) => r.rating >= filter.minRating!);
    }
    if (filter.maxPriceLevel != null) {
      result =
          result.where((RestaurantModel r) => r.priceLevel <= filter.maxPriceLevel!);
    }

    final List<RestaurantModel> sorted = result.toList(growable: false);
    sorted.sort((RestaurantModel a, RestaurantModel b) {
      return switch (filter.sort) {
        RestaurantSort.rating => b.rating.compareTo(a.rating),
        RestaurantSort.deliveryTime =>
          a.etaMinMinutes.compareTo(b.etaMinMinutes),
        RestaurantSort.deliveryFee =>
          a.deliveryFeeMyr.compareTo(b.deliveryFeeMyr),
        RestaurantSort.distance => a.distanceKm.compareTo(b.distanceKm),
        // "Recommended" blends rating and proximity so it is not just a
        // duplicate of the rating sort.
        RestaurantSort.recommended =>
          _recommendationScore(b).compareTo(_recommendationScore(a)),
      };
    });
    return sorted;
  }

  double _recommendationScore(Restaurant r) {
    final double promotedBoost = r.isPromoted ? 0.6 : 0;
    final double openBoost = r.isOpen ? 0.4 : -2;
    final double proximity = (10 - r.distanceKm).clamp(0, 10) / 10;
    return r.rating + promotedBoost + openBoost + proximity;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
