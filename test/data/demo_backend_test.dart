import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/config/app_config.dart';
import 'package:food_delivery_app/core/error/exceptions.dart';
import 'package:food_delivery_app/core/network/connectivity_service.dart';
import 'package:food_delivery_app/core/storage/local_storage.dart';
import 'package:food_delivery_app/core/utils/result.dart';
import 'package:food_delivery_app/data/datasources/local/demo_data_source.dart';
import 'package:food_delivery_app/data/repositories/cart_repository_impl.dart';
import 'package:food_delivery_app/data/repositories/catalog_repository_impl.dart';
import 'package:food_delivery_app/data/repositories/order_repository_impl.dart';
import 'package:food_delivery_app/domain/entities/cart.dart';
import 'package:food_delivery_app/domain/entities/food_item.dart';
import 'package:food_delivery_app/domain/entities/order.dart';
import 'package:food_delivery_app/domain/entities/restaurant.dart';
import 'package:food_delivery_app/domain/repositories/catalog_repository.dart';
import 'package:food_delivery_app/domain/usecases/cart_usecases.dart';
import 'package:food_delivery_app/domain/usecases/order_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/seed_users.dart';

/// Integration-style coverage over the demo backend and the repositories that
/// sit on top of it - the path every screen actually takes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DemoDataSource remote;
  late LocalStorage storage;
  late CatalogRepositoryImpl catalog;
  late CartRepositoryImpl cart;
  late OrderRepositoryImpl orders;

  setUp(() async {
    // No artificial latency in tests, and a fresh in-memory prefs store.
    AppConfig.override(
      const AppConfig(
        simulatedLatency: Duration.zero,
        orderStageDuration: Duration(milliseconds: 20),
      ),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});

    remote = DemoDataSource.instance..reset();
    storage = await LocalStorage.create();
    catalog = CatalogRepositoryImpl(
      remote: remote,
      storage: storage,
      connectivity: ConnectivityService(),
    );
    cart = CartRepositoryImpl(storage: storage);
    orders = OrderRepositoryImpl(remote: remote);
  });

  tearDown(() => AppConfig.override(const AppConfig()));

  group('Catalogue', () {
    test('returns all seeded restaurants', () async {
      final Result<List<Restaurant>> result = await catalog.getRestaurants();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(20));
    });

    test('filters by free delivery', () async {
      final Result<List<Restaurant>> result = await catalog.getRestaurants(
        const RestaurantFilter(freeDeliveryOnly: true),
      );

      expect(result.valueOrNull, isNotEmpty);
      for (final Restaurant r in result.valueOrNull!) {
        expect(r.hasFreeDelivery, isTrue);
      }
    });

    test('sorts by rating, highest first', () async {
      final Result<List<Restaurant>> result = await catalog.getRestaurants(
        const RestaurantFilter(sort: RestaurantSort.rating),
      );
      final List<Restaurant> list = result.valueOrNull!;

      for (int i = 1; i < list.length; i++) {
        expect(list[i - 1].rating, greaterThanOrEqualTo(list[i].rating));
      }
    });

    test('search matches restaurant names and dish names', () async {
      final Result<SearchResults> result = await catalog.search('nasi lemak');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.dishes, isNotEmpty);
    });

    test('search on an unknown term returns an empty result, not an error',
        () async {
      final Result<SearchResults> result =
          await catalog.search('zzzzz-not-a-dish');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.isEmpty, isTrue);
    });

    test('an unknown restaurant id fails with NotFound', () async {
      final Result<Restaurant> result =
          await catalog.getRestaurantById('does-not-exist');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('does-not-exist'));
    });
  });

  group('Cart persistence', () {
    test('adding a dish persists it across repository instances', () async {
      final Restaurant restaurant =
          (await catalog.getRestaurantById('r-01')).valueOrNull!;
      final FoodItem dish =
          (await catalog.getMenuForRestaurant('r-01')).valueOrNull!.first;

      await cart.addItem(item: dish, restaurant: restaurant, quantity: 2);

      // A fresh repository reads the same LocalStorage, mimicking a restart.
      final CartRepositoryImpl reopened = CartRepositoryImpl(storage: storage);
      final Cart restored = (await reopened.load()).valueOrNull!;

      expect(restored.itemCount, 2);
      expect(restored.restaurantId, 'r-01');
    });

    test('rejects a dish from a second restaurant', () async {
      final Restaurant first =
          (await catalog.getRestaurantById('r-01')).valueOrNull!;
      final FoodItem firstDish =
          (await catalog.getMenuForRestaurant('r-01')).valueOrNull!.first;
      final Restaurant second =
          (await catalog.getRestaurantById('r-03')).valueOrNull!;
      final FoodItem secondDish =
          (await catalog.getMenuForRestaurant('r-03')).valueOrNull!.first;

      await cart.addItem(item: firstDish, restaurant: first);
      final Result<Cart> conflict =
          await cart.addItem(item: secondDish, restaurant: second);

      expect(conflict.isFailure, isTrue);
      expect(conflict.failureOrNull!.message, contains('Clear it'));
    });

    test('setting quantity to zero removes the line', () async {
      final Restaurant restaurant =
          (await catalog.getRestaurantById('r-01')).valueOrNull!;
      final FoodItem dish =
          (await catalog.getMenuForRestaurant('r-01')).valueOrNull!.first;

      final Cart withItem =
          (await cart.addItem(item: dish, restaurant: restaurant)).valueOrNull!;

      final UpdateCartQuantity update = UpdateCartQuantity(cart);
      final Result<Cart> emptied = await update(
        UpdateQuantityParams(lineId: withItem.lines.first.lineId, quantity: 0),
      );

      expect(emptied.valueOrNull!.isEmpty, isTrue);
    });
  });

  group('Placing an order', () {
    test('creates an order and empties the cart', () async {
      final Restaurant restaurant =
          (await catalog.getRestaurantById('r-01')).valueOrNull!;
      final FoodItem dish =
          (await catalog.getMenuForRestaurant('r-01')).valueOrNull!.first;

      final Cart basket = (await cart.addItem(
        item: dish,
        restaurant: restaurant,
        quantity: 3,
      ))
          .valueOrNull!;

      final PlaceOrder placeOrder = PlaceOrder(orders, cart);
      final Result<Order> result = await placeOrder(
        PlaceOrderParams(
          cart: basket,
          address: testAddress,
          paymentMethod: PaymentMethod.grabPay,
          user: testCustomer,
        ),
      );

      expect(result.isSuccess, isTrue);
      final Order order = result.valueOrNull!;
      expect(order.status, OrderStatus.placed);
      expect(order.itemCount, 3);
      expect(order.total, closeTo(basket.total, 0.001));

      // The use case clears the basket so a stale cart cannot linger.
      expect((await cart.load()).valueOrNull!.isEmpty, isTrue);
    });

    test('refuses to place an empty order', () async {
      final PlaceOrder placeOrder = PlaceOrder(orders, cart);
      final Result<Order> result = await placeOrder(
        const PlaceOrderParams(
          cart: Cart.empty,
          address: testAddress,
          paymentMethod: PaymentMethod.cash,
          user: testCustomer,
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('empty'));
    });

    test('the order advances through its stages on its own', () async {
      final Restaurant restaurant =
          (await catalog.getRestaurantById('r-01')).valueOrNull!;
      final FoodItem dish =
          (await catalog.getMenuForRestaurant('r-01')).valueOrNull!.first;

      final Cart basket =
          (await cart.addItem(item: dish, restaurant: restaurant)).valueOrNull!;

      final Order order = (await orders.placeOrder(
        cart: basket,
        deliveryAddress: testAddress,
        paymentMethod: PaymentMethod.grabPay,
        userId: testCustomer.id,
        customerName: testCustomer.name,
        customerPhone: testCustomer.phone,
      ))
          .valueOrNull!;

      // orderStageDuration is 20ms in this suite, so a short wait covers
      // several transitions.
      await Future<void>.delayed(const Duration(milliseconds: 120));

      final Order later = (await orders.getOrderById(order.id)).valueOrNull!;
      expect(later.status.index, greaterThan(OrderStatus.placed.index));
      expect(later.timeline.length, greaterThan(1));
    });
  });

  group('Partner order flow', () {
    test('advancing status is reflected for the customer', () async {
      final Order incoming = (await orders.getOrdersForRestaurant('r-06'))
          .valueOrNull!
          .firstWhere((Order o) => o.status == OrderStatus.placed);

      final Result<Order> updated = await orders.updateStatus(
        orderId: incoming.id,
        status: OrderStatus.confirmed,
      );

      expect(updated.valueOrNull!.status, OrderStatus.confirmed);

      final Order reread =
          (await orders.getOrderById(incoming.id)).valueOrNull!;
      expect(reread.status, OrderStatus.confirmed);
    });

    test('cancelling records a reason on the timeline', () async {
      final Order target = (await orders.getOrdersForRestaurant('r-06'))
          .valueOrNull!
          .firstWhere((Order o) => o.status == OrderStatus.placed);

      final Order cancelled = (await orders.cancelOrder(
        target.id,
        reason: 'Out of stock',
      ))
          .valueOrNull!;

      expect(cancelled.status, OrderStatus.cancelled);
      expect(cancelled.timeline.last.note, 'Out of stock');
    });
  });

  group('Demo data source errors', () {
    test('missing ids raise NotFoundException', () async {
      expect(
        () => remote.getFoodById('nope'),
        throwsA(isA<NotFoundException>()),
      );
      expect(
        () => remote.getOrderById('nope'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('reset restores the seeded state', () async {
      await remote.deleteFood('r-01-f01');
      expect(
        (await remote.getMenu('r-01')).where((dynamic f) => f.id == 'r-01-f01'),
        isEmpty,
      );

      remote.reset();

      expect(
        (await remote.getMenu('r-01')).where((dynamic f) => f.id == 'r-01-f01'),
        isNotEmpty,
      );
    });
  });
}
