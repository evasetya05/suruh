part of 'orders_cubit.dart';

enum OrdersStatus { initial, loading, success, failure }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const <Order>[],
    this.errorMessage,
  });

  final OrdersStatus status;
  final List<Order> orders;
  final String? errorMessage;

  bool get isLoading =>
      status == OrdersStatus.loading || status == OrdersStatus.initial;

  /// Orders still in progress, shown in their own tab with live status.
  List<Order> get active =>
      orders.where((Order o) => o.isActive).toList(growable: false);

  List<Order> get past =>
      orders.where((Order o) => !o.isActive).toList(growable: false);

  OrdersState copyWith({
    OrdersStatus? status,
    List<Order>? orders,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, orders, errorMessage];
}
