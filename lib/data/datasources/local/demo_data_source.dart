import 'dart:async';

import '../../../core/config/app_config.dart';
import '../../../core/error/exceptions.dart';
import '../../../domain/entities/order.dart';
import '../../models/food_item_model.dart';
import '../../models/order_model.dart';
import '../../models/promo_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import 'seed/seed_categories.dart';
import 'seed/seed_foods.dart';
import 'seed/seed_orders.dart';
import 'seed/seed_promos.dart';
import 'seed/seed_restaurants.dart';
import 'seed/seed_reviews.dart';
import 'seed/seed_users.dart';

/// In-memory backend that stands in for Firebase.
///
/// It is a real backend as far as the rest of the app is concerned: it holds
/// mutable state, applies latency, emits change streams, and drives the order
/// lifecycle forward on a timer. Repositories cannot tell it apart from the
/// Firestore implementation, which is the whole point of the repository
/// boundary.
///
/// State lives for the lifetime of the process. Anything that must survive a
/// restart (session, cart, favourites) is persisted separately by
/// [LocalStorage].
class DemoDataSource {
  DemoDataSource._() {
    _seed();
  }

  static final DemoDataSource instance = DemoDataSource._();

  // --- Stores ---------------------------------------------------------------
  final List<RestaurantModel> _restaurants = <RestaurantModel>[];
  final List<FoodItemModel> _foods = <FoodItemModel>[];
  final List<ReviewModel> _reviews = <ReviewModel>[];
  final List<OrderModel> _orders = <OrderModel>[];
  final List<UserModel> _users = <UserModel>[];

  final StreamController<List<OrderModel>> _orderStream =
      StreamController<List<OrderModel>>.broadcast();

  /// Timers advancing live orders through their delivery stages.
  final Map<String, Timer> _simulations = <String, Timer>{};

  int _orderSequence = 0;

  void _seed() {
    _restaurants
      ..clear()
      ..addAll(kSeedRestaurants);
    _foods
      ..clear()
      ..addAll(buildSeedFoods());
    _reviews
      ..clear()
      ..addAll(buildSeedReviews(restaurants: _restaurants, foods: _foods));
    _orders
      ..clear()
      ..addAll(buildSeedOrders(restaurants: _restaurants, foods: _foods));
    _users
      ..clear()
      ..addAll(kSeedUsers);

    // Keep the pre-seeded live order moving so the tracking screen is alive on
    // first launch rather than frozen mid-delivery.
    for (final OrderModel order in _orders.where(
      (OrderModel o) => o.status == OrderStatus.outForDelivery,
    )) {
      _scheduleAdvance(order.id);
    }
  }

  /// Resets every store back to the seeded state. Used by tests and by the
  /// "reset demo data" action in the profile screen.
  void reset() {
    pauseSimulations();
    _orderSequence = 0;
    _seed();
    _emitOrders();
  }

  /// Stops every in-flight delivery simulation without touching stored data.
  ///
  /// Orders stay exactly where they are. Tests use this so no timer outlives
  /// the test; it is also what a "pause the demo" control would call.
  void pauseSimulations() {
    for (final Timer timer in _simulations.values) {
      timer.cancel();
    }
    _simulations.clear();
  }

  /// Applies the configured artificial latency so loading states are visible.
  Future<void> _latency([double factor = 1]) => Future<void>.delayed(
        AppConfig.instance.simulatedLatency * factor,
      );

  // --- Catalogue ------------------------------------------------------------
  Future<List<FoodCategoryModel>> getCategories() async {
    await _latency(0.4);
    // Item counts are derived rather than stored so they stay correct after a
    // partner adds or deletes a dish.
    return kSeedCategories
        .map(
          (FoodCategoryModel c) => FoodCategoryModel(
            id: c.id,
            name: c.name,
            emoji: c.emoji,
            itemCount:
                _foods.where((FoodItemModel f) => f.categoryId == c.id).length,
          ),
        )
        .toList(growable: false);
  }

  Future<List<RestaurantModel>> getRestaurants() async {
    await _latency();
    return List<RestaurantModel>.unmodifiable(_restaurants);
  }

  Future<RestaurantModel> getRestaurantById(String id) async {
    await _latency(0.6);
    final RestaurantModel? match =
        _restaurants.where((RestaurantModel r) => r.id == id).firstOrNull;
    if (match == null) {
      throw NotFoundException('No restaurant with id "$id"');
    }
    return match;
  }

  Future<RestaurantModel> getRestaurantByOwner(String ownerId) async {
    await _latency(0.6);
    final RestaurantModel? match = _restaurants
        .where((RestaurantModel r) => r.ownerId == ownerId)
        .firstOrNull;
    if (match == null) {
      throw NotFoundException('No restaurant managed by "$ownerId"');
    }
    return match;
  }

  Future<List<FoodItemModel>> getFoods() async {
    await _latency();
    return List<FoodItemModel>.unmodifiable(_foods);
  }

  Future<List<FoodItemModel>> getMenu(String restaurantId) async {
    await _latency(0.8);
    return _foods
        .where((FoodItemModel f) => f.restaurantId == restaurantId)
        .toList(growable: false);
  }

  Future<FoodItemModel> getFoodById(String id) async {
    await _latency(0.6);
    final FoodItemModel? match =
        _foods.where((FoodItemModel f) => f.id == id).firstOrNull;
    if (match == null) {
      throw NotFoundException('No dish with id "$id"');
    }
    return match;
  }

  Future<List<PromoModel>> getPromos() async {
    await _latency(0.3);
    return List<PromoModel>.unmodifiable(kSeedPromos);
  }

  // --- Reviews --------------------------------------------------------------
  Future<List<ReviewModel>> getReviewsForRestaurant(String restaurantId) async {
    await _latency(0.7);
    return _reviews
        .where((ReviewModel r) => r.restaurantId == restaurantId)
        .toList(growable: false);
  }

  Future<List<ReviewModel>> getReviewsForFood(String foodItemId) async {
    await _latency(0.5);
    return _reviews
        .where((ReviewModel r) => r.foodItemId == foodItemId)
        .toList(growable: false);
  }

  Future<ReviewModel> addReview(ReviewModel review) async {
    await _latency();
    _reviews.insert(0, review);

    // Recompute the restaurant's headline rating from its reviews so the change
    // is visible immediately on the listing screens.
    final int index =
        _restaurants.indexWhere((RestaurantModel r) => r.id == review.restaurantId);
    if (index != -1) {
      final List<ReviewModel> all = _reviews
          .where((ReviewModel r) => r.restaurantId == review.restaurantId)
          .toList(growable: false);
      final double average =
          all.fold<double>(0, (double s, ReviewModel r) => s + r.rating) /
              all.length;
      _restaurants[index] = RestaurantModel.fromEntity(
        _restaurants[index].copyWith(
          rating: double.parse(average.toStringAsFixed(1)),
          reviewCount: _restaurants[index].reviewCount + 1,
        ),
      );
    }
    return review;
  }

  // --- Users ----------------------------------------------------------------
  Future<UserModel?> findUserByEmail(String email) async {
    await _latency(0.8);
    return _users
        .where(
          (UserModel u) => u.email.toLowerCase() == email.toLowerCase().trim(),
        )
        .firstOrNull;
  }

  Future<UserModel> getUserById(String id) async {
    await _latency(0.5);
    final UserModel? match =
        _users.where((UserModel u) => u.id == id).firstOrNull;
    if (match == null) {
      throw NotFoundException('No user with id "$id"');
    }
    return match;
  }

  Future<UserModel> upsertUser(UserModel user) async {
    await _latency(0.6);
    final int index = _users.indexWhere((UserModel u) => u.id == user.id);
    if (index == -1) {
      _users.add(user);
    } else {
      _users[index] = user;
    }
    return user;
  }

  // --- Orders ---------------------------------------------------------------
  Future<List<OrderModel>> getOrders() async {
    await _latency();
    return List<OrderModel>.unmodifiable(_orders);
  }

  Future<OrderModel> getOrderById(String id) async {
    await _latency(0.5);
    final OrderModel? match =
        _orders.where((OrderModel o) => o.id == id).firstOrNull;
    if (match == null) {
      throw NotFoundException('No order with id "$id"');
    }
    return match;
  }

  /// Broadcast of the full order book. Repositories filter it per screen.
  Stream<List<OrderModel>> watchOrders() async* {
    yield List<OrderModel>.unmodifiable(_orders);
    yield* _orderStream.stream;
  }

  String nextOrderId() {
    _orderSequence++;
    final DateTime now = DateTime.now();
    final String stamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return 'o-$stamp-${_orderSequence.toString().padLeft(4, '0')}';
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    await _latency(1.6);
    _orders.insert(0, order);
    _emitOrders();
    _scheduleAdvance(order.id);
    return order;
  }

  Future<OrderModel> updateOrder(OrderModel order) async {
    await _latency(0.6);
    final int index = _orders.indexWhere((OrderModel o) => o.id == order.id);
    if (index == -1) {
      throw NotFoundException('No order with id "${order.id}"');
    }
    _orders[index] = order;
    _emitOrders();

    if (order.status.isTerminal) {
      _simulations.remove(order.id)?.cancel();
    } else {
      _scheduleAdvance(order.id);
    }
    return order;
  }

  /// Moves an order to its next status after [AppConfig.orderStageDuration].
  ///
  /// This is what makes the tracking screen feel live without a server: place
  /// an order and watch it walk through confirmed -> preparing -> out for
  /// delivery -> delivered on its own.
  void _scheduleAdvance(String orderId) {
    _simulations.remove(orderId)?.cancel();

    _simulations[orderId] = Timer(AppConfig.instance.orderStageDuration, () {
      final int index = _orders.indexWhere((OrderModel o) => o.id == orderId);
      if (index == -1) return;

      final OrderModel current = _orders[index];
      final OrderStatus? next = current.status.next;
      if (next == null) {
        _simulations.remove(orderId);
        return;
      }

      OrderModel updated = OrderModel.fromEntity(current.advanceTo(next));

      // Assign a rider the moment the kitchen hands the order over.
      if (next == OrderStatus.readyForPickup && updated.rider == null) {
        final (String id, String name, String vehicle, String plate, double r) =
            kRiderPool[_orders.length % kRiderPool.length];
        updated = OrderModel.fromEntity(
          updated.copyWith(
            rider: DeliveryRider(
              id: id,
              name: name,
              vehicle: vehicle,
              plateNumber: plate,
              rating: r,
            ),
          ),
        );
      }

      _orders[index] = updated;
      _emitOrders();

      if (!updated.status.isTerminal) {
        _scheduleAdvance(orderId);
      } else {
        _simulations.remove(orderId);
      }
    });
  }

  void _emitOrders() {
    if (_orderStream.isClosed) return;
    _orderStream.add(List<OrderModel>.unmodifiable(_orders));
  }

  // --- Partner menu management ----------------------------------------------
  Future<FoodItemModel> addFood(FoodItemModel item) async {
    await _latency();
    _foods.add(item);
    return item;
  }

  Future<FoodItemModel> updateFood(FoodItemModel item) async {
    await _latency(0.7);
    final int index = _foods.indexWhere((FoodItemModel f) => f.id == item.id);
    if (index == -1) {
      throw NotFoundException('No dish with id "${item.id}"');
    }
    _foods[index] = item;
    return item;
  }

  Future<void> deleteFood(String id) async {
    await _latency(0.7);
    final int index = _foods.indexWhere((FoodItemModel f) => f.id == id);
    if (index == -1) {
      throw NotFoundException('No dish with id "$id"');
    }
    _foods.removeAt(index);
  }

  Future<RestaurantModel> updateRestaurant(RestaurantModel restaurant) async {
    await _latency(0.6);
    final int index =
        _restaurants.indexWhere((RestaurantModel r) => r.id == restaurant.id);
    if (index == -1) {
      throw NotFoundException('No restaurant with id "${restaurant.id}"');
    }
    _restaurants[index] = restaurant;
    return restaurant;
  }

  /// Next sequential dish id for a restaurant, e.g. `r-06-f06`.
  String nextFoodId(String restaurantId) {
    final int count =
        _foods.where((FoodItemModel f) => f.restaurantId == restaurantId).length;
    return '$restaurantId-f${(count + 1).toString().padLeft(2, '0')}';
  }

  Future<void> dispose() async {
    for (final Timer timer in _simulations.values) {
      timer.cancel();
    }
    _simulations.clear();
    await _orderStream.close();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
