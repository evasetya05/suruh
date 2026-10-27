import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/local/demo_data_source.dart';
import '../models/address_model.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({required DemoDataSource remote}) : _remote = remote;

  final DemoDataSource _remote;

  @override
  Future<Result<Order>> placeOrder({
    required Cart cart,
    required Address deliveryAddress,
    required PaymentMethod paymentMethod,
    required String userId,
    required String customerName,
    required String customerPhone,
    String? riderNote,
  }) {
    return guard<Order>(() async {
      final DateTime now = DateTime.now();

      // Totals are recomputed from the cart entity rather than trusted from the
      // UI, so a stale checkout screen can never post a wrong price.
      final OrderModel order = OrderModel(
        id: _remote.nextOrderId(),
        userId: userId,
        restaurantId: cart.restaurantId!,
        restaurantName: cart.restaurantName,
        restaurantEmoji: '🍽️',
        lines: cart.lines,
        status: OrderStatus.placed,
        placedAt: now,
        deliveryAddress: AddressModel.fromEntity(deliveryAddress),
        paymentMethod: paymentMethod,
        subtotal: cart.subtotal,
        deliveryFee: cart.deliveryFeeMyr,
        serviceFee: cart.serviceFee + cart.smallOrderFee,
        discount: cart.promoDiscount,
        total: cart.total,
        customerName: customerName,
        customerPhone: customerPhone,
        timeline: <OrderEvent>[
          OrderEvent(status: OrderStatus.placed, at: now),
        ],
        etaMinutes: 35,
        riderNote: riderNote,
      );

      return _remote.createOrder(order);
    });
  }

  @override
  Future<Result<Order>> getOrderById(String orderId) =>
      guard<Order>(() => _remote.getOrderById(orderId));

  @override
  Stream<Order> watchOrder(String orderId) => _remote
      .watchOrders()
      .map(
        (List<OrderModel> orders) =>
            orders.where((OrderModel o) => o.id == orderId).firstOrNull,
      )
      .where((OrderModel? o) => o != null)
      .cast<Order>()
      .distinct();

  @override
  Future<Result<List<Order>>> getOrdersForUser(String userId) {
    return guard<List<Order>>(() async {
      final List<OrderModel> all = await _remote.getOrders();
      return all
          .where((OrderModel o) => o.userId == userId)
          .toList(growable: false);
    });
  }

  @override
  Future<Result<List<Order>>> getOrdersForRestaurant(String restaurantId) {
    return guard<List<Order>>(() async {
      final List<OrderModel> all = await _remote.getOrders();
      return all
          .where((OrderModel o) => o.restaurantId == restaurantId)
          .toList(growable: false);
    });
  }

  @override
  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId) =>
      _remote.watchOrders().map(
            (List<OrderModel> orders) => orders
                .where((OrderModel o) => o.restaurantId == restaurantId)
                .toList(growable: false),
          );

  @override
  Future<Result<List<Order>>> getOrdersForRider(String riderId) {
    return guard<List<Order>>(() async {
      final List<OrderModel> all = await _remote.getOrders();
      return _riderQueue(all, riderId);
    });
  }

  @override
  Stream<List<Order>> watchOrdersForRider(String riderId) => _remote
      .watchOrders()
      .map((List<OrderModel> orders) => _riderQueue(orders, riderId));

  /// A rider sees orders assigned to them plus anything ready for pickup that
  /// nobody has claimed yet.
  List<Order> _riderQueue(List<OrderModel> orders, String riderId) {
    return orders
        .where(
          (OrderModel o) =>
              o.rider?.id == riderId ||
              (o.status == OrderStatus.readyForPickup && o.rider == null),
        )
        .toList(growable: false);
  }

  @override
  Future<Result<Order>> updateStatus({
    required String orderId,
    required OrderStatus status,
    String? note,
  }) {
    return guard<Order>(() async {
      final OrderModel current = await _remote.getOrderById(orderId);
      final OrderModel updated =
          OrderModel.fromEntity(current.advanceTo(status, note: note));
      return _remote.updateOrder(updated);
    });
  }

  @override
  Future<Result<Order>> cancelOrder(String orderId, {String? reason}) {
    return guard<Order>(() async {
      final OrderModel current = await _remote.getOrderById(orderId);
      final OrderModel updated = OrderModel.fromEntity(
        current.advanceTo(
          OrderStatus.cancelled,
          note: reason ?? 'Cancelled by customer',
        ),
      );
      return _remote.updateOrder(updated);
    });
  }

  @override
  Future<Result<Order>> markRated(String orderId) {
    return guard<Order>(() async {
      final OrderModel current = await _remote.getOrderById(orderId);
      return _remote.updateOrder(
        OrderModel.fromEntity(current.copyWith(isRated: true)),
      );
    });
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
