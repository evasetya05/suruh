import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/address.dart';
import '../entities/cart.dart';
import '../entities/order.dart';
import '../entities/user.dart';
import '../repositories/cart_repository.dart';
import '../repositories/order_repository.dart';

class PlaceOrderParams extends Equatable {
  const PlaceOrderParams({
    required this.cart,
    required this.address,
    required this.paymentMethod,
    required this.user,
    this.riderNote,
  });

  final Cart cart;
  final Address address;
  final PaymentMethod paymentMethod;
  final User user;
  final String? riderNote;

  @override
  List<Object?> get props =>
      <Object?>[cart, address, paymentMethod, user, riderNote];
}

/// Validates the basket, creates the order, then empties the cart.
///
/// Clearing the cart is deliberately part of this use case rather than the UI:
/// an order that exists with a stale cart behind it is a real bug class.
class PlaceOrder extends UseCase<Order, PlaceOrderParams> {
  const PlaceOrder(this._orders, this._cart);

  final OrderRepository _orders;
  final CartRepository _cart;

  @override
  Future<Result<Order>> call(PlaceOrderParams params) async {
    if (params.cart.isEmpty) {
      return const Result<Order>.failure(
        ValidationFailure('Your cart is empty.'),
      );
    }

    final Result<Order> result = await _orders.placeOrder(
      cart: params.cart,
      deliveryAddress: params.address,
      paymentMethod: params.paymentMethod,
      userId: params.user.id,
      customerName: params.user.name,
      customerPhone: params.user.phone,
      riderNote: params.riderNote,
    );

    if (result.isSuccess) {
      await _cart.clear();
    }
    return result;
  }
}

class GetOrderHistory extends UseCase<List<Order>, String> {
  const GetOrderHistory(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<List<Order>>> call(String userId) =>
      _repository.getOrdersForUser(userId);
}

class GetOrderById extends UseCase<Order, String> {
  const GetOrderById(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(String orderId) =>
      _repository.getOrderById(orderId);
}

/// Live order updates for the tracking screen.
class WatchOrder extends StreamUseCase<Order, String> {
  const WatchOrder(this._repository);

  final OrderRepository _repository;

  @override
  Stream<Order> call(String orderId) => _repository.watchOrder(orderId);
}

class UpdateOrderStatusParams extends Equatable {
  const UpdateOrderStatusParams({
    required this.orderId,
    required this.status,
    this.note,
  });

  final String orderId;
  final OrderStatus status;
  final String? note;

  @override
  List<Object?> get props => <Object?>[orderId, status, note];
}

class UpdateOrderStatus extends UseCase<Order, UpdateOrderStatusParams> {
  const UpdateOrderStatus(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(UpdateOrderStatusParams params) =>
      _repository.updateStatus(
        orderId: params.orderId,
        status: params.status,
        note: params.note,
      );
}

class CancelOrder extends UseCase<Order, String> {
  const CancelOrder(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<Order>> call(String orderId) =>
      _repository.cancelOrder(orderId);
}

class WatchRestaurantOrders extends StreamUseCase<List<Order>, String> {
  const WatchRestaurantOrders(this._repository);

  final OrderRepository _repository;

  @override
  Stream<List<Order>> call(String restaurantId) =>
      _repository.watchOrdersForRestaurant(restaurantId);
}

class WatchRiderOrders extends StreamUseCase<List<Order>, String> {
  const WatchRiderOrders(this._repository);

  final OrderRepository _repository;

  @override
  Stream<List<Order>> call(String riderId) =>
      _repository.watchOrdersForRider(riderId);
}
