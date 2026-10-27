import '../../core/utils/result.dart';
import '../entities/food_item.dart';
import '../entities/restaurant.dart';

/// Aggregated numbers on the restaurant partner dashboard.
class PartnerStats {
  const PartnerStats({
    required this.todayRevenue,
    required this.todayOrders,
    required this.pendingOrders,
    required this.activeMenuItems,
    required this.averageRating,
    required this.totalReviews,
    required this.revenueByDay,
  });

  final double todayRevenue;
  final int todayOrders;
  final int pendingOrders;
  final int activeMenuItems;
  final double averageRating;
  final int totalReviews;

  /// Last 7 days of revenue, oldest first - drives the dashboard sparkline.
  final List<double> revenueByDay;
}

/// Restaurant-partner operations: menu CRUD, availability, dashboard stats.
abstract interface class PartnerRepository {
  Future<Result<Restaurant>> getManagedRestaurant(String ownerId);

  Future<Result<PartnerStats>> getStats(String restaurantId);

  Future<Result<List<FoodItem>>> getMenu(String restaurantId);

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
  });

  Future<Result<FoodItem>> updateMenuItem(FoodItem item);

  Future<Result<void>> deleteMenuItem(String foodItemId);

  /// Fast toggle for the "sold out" switch on the menu list.
  Future<Result<FoodItem>> setItemAvailability({
    required String foodItemId,
    required bool isAvailable,
  });

  /// Opens or closes the storefront for new orders.
  Future<Result<Restaurant>> setRestaurantOpen({
    required String restaurantId,
    required bool isOpen,
  });
}
