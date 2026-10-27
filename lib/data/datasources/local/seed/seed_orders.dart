import 'dart:math';

import '../../../../domain/entities/cart.dart';
import '../../../../domain/entities/order.dart';
import '../../../models/food_item_model.dart';
import '../../../models/order_model.dart';
import '../../../models/restaurant_model.dart';
import 'seed_users.dart';

/// Builds the seeded order book.
///
/// It has to satisfy three screens at once:
///  * customer order history (delivered orders across several restaurants),
///  * one live order so tracking has something to animate on first launch,
///  * a spread of statuses on restaurant `r-06` so the partner dashboard's
///    incoming / in-kitchen / completed queues are all populated.
List<OrderModel> buildSeedOrders({
  required List<RestaurantModel> restaurants,
  required List<FoodItemModel> foods,
}) {
  final Random random = Random(31072026);
  final DateTime now = DateTime.now();
  final List<OrderModel> orders = <OrderModel>[];

  RestaurantModel restaurantById(String id) =>
      restaurants.firstWhere((RestaurantModel r) => r.id == id);

  List<CartItem> linesFor(String restaurantId, int count) {
    final List<FoodItemModel> menu = foods
        .where((FoodItemModel f) => f.restaurantId == restaurantId)
        .toList(growable: false);
    final Set<int> picked = <int>{};
    while (picked.length < count && picked.length < menu.length) {
      picked.add(random.nextInt(menu.length));
    }
    return picked
        .map(
          (int i) => CartItem(item: menu[i], quantity: 1 + random.nextInt(2)),
        )
        .toList(growable: false);
  }

  DeliveryRider riderAt(int index) {
    final (String id, String name, String vehicle, String plate, double rating) =
        kRiderPool[index % kRiderPool.length];
    return DeliveryRider(
      id: id,
      name: name,
      vehicle: vehicle,
      plateNumber: plate,
      rating: rating,
    );
  }

  /// Builds a plausible timeline ending at [status].
  List<OrderEvent> timelineFor(OrderStatus status, DateTime placedAt) {
    const List<OrderStatus> path = <OrderStatus>[
      OrderStatus.placed,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.readyForPickup,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    if (status == OrderStatus.cancelled) {
      return <OrderEvent>[
        OrderEvent(status: OrderStatus.placed, at: placedAt),
        OrderEvent(
          status: OrderStatus.cancelled,
          at: placedAt.add(const Duration(minutes: 4)),
          note: 'Restaurant could not accept the order',
        ),
      ];
    }
    final int endIndex = path.indexOf(status);
    return <OrderEvent>[
      for (int i = 0; i <= endIndex; i++)
        OrderEvent(
          status: path[i],
          at: placedAt.add(Duration(minutes: i * 6)),
        ),
    ];
  }

  OrderModel build({
    required String id,
    required String restaurantId,
    required OrderStatus status,
    required DateTime placedAt,
    required int lineCount,
    String userId = 'u-customer',
    String customerName = 'Aisyah Rahman',
    String customerPhone = '012-345 6789',
    PaymentMethod payment = PaymentMethod.grabPay,
    int riderIndex = 0,
    double discount = 0,
    bool isRated = false,
    String? riderNote,
  }) {
    final RestaurantModel restaurant = restaurantById(restaurantId);
    final List<CartItem> lines = linesFor(restaurantId, lineCount);
    final double subtotal =
        lines.fold<double>(0, (double s, CartItem l) => s + l.lineTotal);
    final double serviceFee = PricingPolicy.serviceFeeFor(subtotal);
    final double total =
        subtotal + restaurant.deliveryFeeMyr + serviceFee - discount;

    // A rider is only attached once the order has left the kitchen.
    final bool hasRider = status == OrderStatus.outForDelivery ||
        status == OrderStatus.delivered ||
        status == OrderStatus.readyForPickup;

    return OrderModel(
      id: id,
      userId: userId,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      restaurantEmoji: restaurant.emoji,
      lines: lines,
      status: status,
      placedAt: placedAt,
      deliveryAddress: kHomeAddress,
      paymentMethod: payment,
      subtotal: subtotal,
      deliveryFee: restaurant.deliveryFeeMyr,
      serviceFee: serviceFee,
      discount: discount,
      total: total < 0 ? 0 : total,
      customerName: customerName,
      customerPhone: customerPhone,
      rider: hasRider ? riderAt(riderIndex) : null,
      timeline: timelineFor(status, placedAt),
      etaMinutes: restaurant.etaMaxMinutes,
      deliveredAt: status == OrderStatus.delivered
          ? placedAt.add(Duration(minutes: restaurant.etaMaxMinutes))
          : null,
      riderNote: riderNote,
      isRated: isRated,
    );
  }

  // --- One live order so the tracking screen animates on first launch -------
  orders.add(
    build(
      id: 'o-live-01',
      restaurantId: 'r-01',
      status: OrderStatus.outForDelivery,
      placedAt: now.subtract(const Duration(minutes: 18)),
      lineCount: 3,
      riderIndex: 0,
      discount: 6.90,
      riderNote: 'Please ring the doorbell, do not knock',
    ),
  );

  // --- Customer history ------------------------------------------------------
  const List<(String, String, int, int, bool)> history =
      <(String, String, int, int, bool)>[
    ('o-h-01', 'r-08', 1, 2, true),
    ('o-h-02', 'r-15', 3, 2, true),
    ('o-h-03', 'r-12', 6, 3, false),
    ('o-h-04', 'r-04', 9, 4, true),
    ('o-h-05', 'r-18', 12, 2, true),
    ('o-h-06', 'r-09', 18, 3, false),
    ('o-h-07', 'r-06', 24, 3, true),
    ('o-h-08', 'r-14', 31, 4, true),
  ];
  for (int i = 0; i < history.length; i++) {
    final (String id, String rid, int daysAgo, int lines, bool rated) =
        history[i];
    orders.add(
      build(
        id: id,
        restaurantId: rid,
        status: OrderStatus.delivered,
        placedAt: now.subtract(Duration(days: daysAgo, hours: 2 + i)),
        lineCount: lines,
        riderIndex: i,
        payment: PaymentMethod.values[i % PaymentMethod.values.length],
        discount: i.isEven ? 5 : 0,
        isRated: rated,
      ),
    );
  }

  // One cancelled order so the history list shows that state too.
  orders.add(
    build(
      id: 'o-h-09',
      restaurantId: 'r-20',
      status: OrderStatus.cancelled,
      placedAt: now.subtract(const Duration(days: 15, hours: 5)),
      lineCount: 2,
    ),
  );

  // --- Partner dashboard queues for r-06 ------------------------------------
  const List<(String, String, String, OrderStatus, int)> partnerOrders =
      <(String, String, String, OrderStatus, int)>[
    ('o-p-01', 'u-c2', 'Tan Chee Meng', OrderStatus.placed, 4),
    ('o-p-02', 'u-c3', 'Priya Suresh', OrderStatus.placed, 2),
    ('o-p-03', 'u-c4', 'Ahmad Faizal', OrderStatus.confirmed, 3),
    ('o-p-04', 'u-c5', 'Wong Li Ping', OrderStatus.preparing, 5),
    ('o-p-05', 'u-c6', 'Daniel Yap', OrderStatus.readyForPickup, 2),
    ('o-p-06', 'u-c7', 'Siti Nabilah', OrderStatus.outForDelivery, 3),
  ];
  for (int i = 0; i < partnerOrders.length; i++) {
    final (String id, String uid, String name, OrderStatus status, int lines) =
        partnerOrders[i];
    orders.add(
      build(
        id: id,
        restaurantId: 'r-06',
        status: status,
        placedAt: now.subtract(Duration(minutes: 8 + i * 11)),
        lineCount: lines,
        userId: uid,
        customerName: name,
        customerPhone: '01${i + 1}-${200 + i}0 ${3300 + i * 7}',
        riderIndex: i,
      ),
    );
  }

  // Some delivered orders today so the partner's revenue stats are non-zero.
  for (int i = 0; i < 5; i++) {
    orders.add(
      build(
        id: 'o-p-done-0${i + 1}',
        restaurantId: 'r-06',
        status: OrderStatus.delivered,
        placedAt: now.subtract(Duration(hours: 2 + i * 2)),
        lineCount: 2 + random.nextInt(3),
        userId: 'u-c${10 + i}',
        customerName: kReviewerPool[i].$2,
        riderIndex: i,
        isRated: true,
      ),
    );
  }

  // --- Rider queue: orders assigned to rd-01 across other restaurants -------
  const List<(String, String, OrderStatus)> riderOrders =
      <(String, String, OrderStatus)>[
    ('o-rd-01', 'r-08', OrderStatus.readyForPickup),
    ('o-rd-02', 'r-12', OrderStatus.outForDelivery),
  ];
  for (int i = 0; i < riderOrders.length; i++) {
    final (String id, String rid, OrderStatus status) = riderOrders[i];
    orders.add(
      build(
        id: id,
        restaurantId: rid,
        status: status,
        placedAt: now.subtract(Duration(minutes: 12 + i * 9)),
        lineCount: 2,
        userId: 'u-c2$i',
        customerName: kReviewerPool[i + 5].$2,
        riderIndex: 0,
      ),
    );
  }

  orders.sort(
    (OrderModel a, OrderModel b) => b.placedAt.compareTo(a.placedAt),
  );
  return orders;
}
