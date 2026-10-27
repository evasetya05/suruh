part of 'partner_bloc.dart';

enum PartnerStatus { initial, loading, success, failure }

class PartnerState extends Equatable {
  const PartnerState({
    this.status = PartnerStatus.initial,
    this.restaurant,
    this.stats,
    this.menu = const <FoodItem>[],
    this.orders = const <Order>[],
    this.busyOrderId,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
  });

  final PartnerStatus status;
  final Restaurant? restaurant;
  final PartnerStats? stats;
  final List<FoodItem> menu;
  final List<Order> orders;

  /// Order currently having its status advanced, so only that row spins.
  final String? busyOrderId;
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;

  bool get isLoading =>
      status == PartnerStatus.loading || status == PartnerStatus.initial;

  PartnerOrderQueues get queues => PartnerOrderQueues.fromOrders(orders);

  /// Live revenue from today's non-cancelled orders. Recomputed from the order
  /// stream rather than the fetched stats, so a new order updates the tile
  /// immediately.
  double get liveTodayRevenue {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    return orders
        .where(
          (Order o) =>
              o.placedAt.isAfter(startOfToday) &&
              o.status != OrderStatus.cancelled,
        )
        .fold<double>(0, (double sum, Order o) => sum + o.subtotal);
  }

  int get liveTodayOrders {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    return orders
        .where(
          (Order o) =>
              o.placedAt.isAfter(startOfToday) &&
              o.status != OrderStatus.cancelled,
        )
        .length;
  }

  PartnerState copyWith({
    PartnerStatus? status,
    Restaurant? restaurant,
    PartnerStats? stats,
    List<FoodItem>? menu,
    List<Order>? orders,
    String? busyOrderId,
    bool? isSaving,
    String? successMessage,
    String? errorMessage,
    bool clearBusyOrder = false,
    bool clearMessages = false,
    bool clearError = false,
  }) {
    return PartnerState(
      status: status ?? this.status,
      restaurant: restaurant ?? this.restaurant,
      stats: stats ?? this.stats,
      menu: menu ?? this.menu,
      orders: orders ?? this.orders,
      busyOrderId: clearBusyOrder ? null : (busyOrderId ?? this.busyOrderId),
      isSaving: isSaving ?? this.isSaving,
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages || clearError
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        restaurant,
        menu,
        orders,
        busyOrderId,
        isSaving,
        successMessage,
        errorMessage,
      ];
}
