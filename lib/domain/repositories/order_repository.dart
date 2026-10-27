import '../../core/utils/result.dart';
import '../entities/address.dart';
import '../entities/cart.dart';
import '../entities/order.dart';

abstract interface class OrderRepository {
  /// Converts a [Cart] into a persisted [Order] and starts the delivery
  /// simulation (demo backend) or triggers a Cloud Function (Firebase).
  Future<Result<Order>> placeOrder({
    required Cart cart,
    required Address deliveryAddress,
    required PaymentMethod paymentMethod,
    required String userId,
    required String customerName,
    required String customerPhone,
    String? riderNote,
  });

  Future<Result<Order>> getOrderById(String orderId);

  /// Live updates for the tracking screen.
  Stream<Order> watchOrder(String orderId);

  Future<Result<List<Order>>> getOrdersForUser(String userId);

  /// Orders belonging to a partner's restaurant, newest first.
  Future<Result<List<Order>>> getOrdersForRestaurant(String restaurantId);

  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId);

  /// Orders assigned to (or claimable by) a delivery rider.
  Future<Result<List<Order>>> getOrdersForRider(String riderId);

  Stream<List<Order>> watchOrdersForRider(String riderId);

  Future<Result<Order>> updateStatus({
    required String orderId,
    required OrderStatus status,
    String? note,
  });

  Future<Result<Order>> cancelOrder(String orderId, {String? reason});

  /// Marks the order as rated so the "Rate your order" prompt disappears.
  Future<Result<Order>> markRated(String orderId);
}
