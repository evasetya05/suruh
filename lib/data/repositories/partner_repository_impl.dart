import '../../core/utils/result.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/partner_repository.dart';
import '../datasources/local/demo_data_source.dart';
import '../models/food_item_model.dart';
import '../models/order_model.dart';
import '../models/restaurant_model.dart';

class PartnerRepositoryImpl implements PartnerRepository {
  PartnerRepositoryImpl({required DemoDataSource remote}) : _remote = remote;

  final DemoDataSource _remote;

  @override
  Future<Result<Restaurant>> getManagedRestaurant(String ownerId) =>
      guard<Restaurant>(() => _remote.getRestaurantByOwner(ownerId));

  @override
  Future<Result<PartnerStats>> getStats(String restaurantId) {
    return guard<PartnerStats>(() async {
      final List<OrderModel> orders = await _remote.getOrders();
      final List<FoodItemModel> menu = await _remote.getMenu(restaurantId);

      final List<OrderModel> mine = orders
          .where((OrderModel o) => o.restaurantId == restaurantId)
          .toList(growable: false);

      final DateTime now = DateTime.now();
      final DateTime startOfToday = DateTime(now.year, now.month, now.day);

      final List<OrderModel> today = mine
          .where(
            (OrderModel o) =>
                o.placedAt.isAfter(startOfToday) &&
                o.status != OrderStatus.cancelled,
          )
          .toList(growable: false);

      // Revenue counts the merchant's take (subtotal), not the customer total,
      // since delivery and service fees belong to the platform.
      final double todayRevenue =
          today.fold<double>(0, (double s, OrderModel o) => s + o.subtotal);

      final List<double> revenueByDay = <double>[
        for (int daysAgo = 6; daysAgo >= 0; daysAgo--)
          _revenueOn(mine, startOfToday.subtract(Duration(days: daysAgo))),
      ];

      final List<RestaurantModel> restaurants = await _remote.getRestaurants();
      final RestaurantModel restaurant = restaurants
          .firstWhere((RestaurantModel r) => r.id == restaurantId);

      return PartnerStats(
        todayRevenue: todayRevenue,
        todayOrders: today.length,
        pendingOrders:
            mine.where((OrderModel o) => o.status == OrderStatus.placed).length,
        activeMenuItems:
            menu.where((FoodItemModel f) => f.isAvailable).length,
        averageRating: restaurant.rating,
        totalReviews: restaurant.reviewCount,
        revenueByDay: revenueByDay,
      );
    });
  }

  double _revenueOn(List<OrderModel> orders, DateTime day) {
    final DateTime end = day.add(const Duration(days: 1));
    return orders
        .where(
          (OrderModel o) =>
              o.status != OrderStatus.cancelled &&
              o.placedAt.isAfter(day) &&
              o.placedAt.isBefore(end),
        )
        .fold<double>(0, (double s, OrderModel o) => s + o.subtotal);
  }

  @override
  Future<Result<List<FoodItem>>> getMenu(String restaurantId) =>
      guard<List<FoodItem>>(() => _remote.getMenu(restaurantId));

  @override
  Future<Result<FoodItem>> createMenuItem({
    required String restaurantId,
    required String name,
    required String description,
    required double priceMyr,
    required String categoryId,
    required String emoji,
    double? discountPriceMyr,
    List<String> ingredients = const <String>[],
    bool isVegetarian = false,
    bool isSpicy = false,
    int prepMinutes = 15,
  }) {
    return guard<FoodItem>(() async {
      final RestaurantModel restaurant =
          await _remote.getRestaurantById(restaurantId);

      final FoodItemModel item = FoodItemModel(
        id: _remote.nextFoodId(restaurantId),
        restaurantId: restaurantId,
        restaurantName: restaurant.name,
        name: name,
        description: description,
        priceMyr: priceMyr,
        discountPriceMyr: discountPriceMyr,
        categoryId: categoryId,
        emoji: emoji,
        // A brand new dish has no history yet; the UI renders "New" instead of
        // a rating when reviewCount is zero.
        rating: 0,
        reviewCount: 0,
        ingredients: ingredients,
        isVegetarian: isVegetarian,
        isSpicy: isSpicy,
        spiceLevel: isSpicy ? 2 : 0,
        prepMinutes: prepMinutes,
      );

      return _remote.addFood(item);
    });
  }

  @override
  Future<Result<FoodItem>> updateMenuItem(FoodItem item) => guard<FoodItem>(
        () => _remote.updateFood(FoodItemModel.fromEntity(item)),
      );

  @override
  Future<Result<void>> deleteMenuItem(String foodItemId) =>
      guard<void>(() => _remote.deleteFood(foodItemId));

  @override
  Future<Result<FoodItem>> setItemAvailability({
    required String foodItemId,
    required bool isAvailable,
  }) {
    return guard<FoodItem>(() async {
      final FoodItemModel current = await _remote.getFoodById(foodItemId);
      return _remote.updateFood(
        FoodItemModel.fromEntity(current.copyWith(isAvailable: isAvailable)),
      );
    });
  }

  @override
  Future<Result<Restaurant>> setRestaurantOpen({
    required String restaurantId,
    required bool isOpen,
  }) {
    return guard<Restaurant>(() async {
      final RestaurantModel current =
          await _remote.getRestaurantById(restaurantId);
      return _remote.updateRestaurant(
        RestaurantModel.fromEntity(current.copyWith(isOpen: isOpen)),
      );
    });
  }
}
