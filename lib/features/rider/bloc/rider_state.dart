part of 'rider_cubit.dart';

enum RiderStatus { initial, loading, success, failure }

class RiderState extends Equatable {
  const RiderState({
    this.status = RiderStatus.initial,
    this.orders = const <Order>[],
    this.riderId = '',
    this.isOnline = true,
    this.busyOrderId,
    this.successMessage,
    this.errorMessage,
  });

  final RiderStatus status;
  final List<Order> orders;
  final String riderId;

  /// Riders can go offline to stop new jobs appearing.
  final bool isOnline;
  final String? busyOrderId;
  final String? successMessage;
  final String? errorMessage;

  bool get isLoading =>
      status == RiderStatus.loading || status == RiderStatus.initial;

  /// Ready for pickup and not yet claimed by anyone.
  List<Order> get available => orders
      .where(
        (Order o) => o.status == OrderStatus.readyForPickup && o.rider == null,
      )
      .toList(growable: false);

  /// Assigned to this rider and still in progress.
  List<Order> get active => orders
      .where((Order o) => o.rider?.id == riderId && o.isActive)
      .toList(growable: false);

  List<Order> get completed => orders
      .where((Order o) => o.rider?.id == riderId && !o.isActive)
      .toList(growable: false);

  /// Rider earnings for completed deliveries: the delivery fee plus a flat
  /// per-drop incentive, which is how the seeded numbers are framed.
  double get todayEarnings {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    return completed
        .where(
          (Order o) =>
              o.status == OrderStatus.delivered &&
              o.placedAt.isAfter(startOfToday),
        )
        .fold<double>(0, (double sum, Order o) => sum + o.deliveryFee + 4);
  }

  int get deliveriesToday {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    return completed
        .where(
          (Order o) =>
              o.status == OrderStatus.delivered &&
              o.placedAt.isAfter(startOfToday),
        )
        .length;
  }

  RiderState copyWith({
    RiderStatus? status,
    List<Order>? orders,
    String? riderId,
    bool? isOnline,
    String? busyOrderId,
    String? successMessage,
    String? errorMessage,
    bool clearBusyOrder = false,
    bool clearMessages = false,
    bool clearError = false,
  }) {
    return RiderState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      riderId: riderId ?? this.riderId,
      isOnline: isOnline ?? this.isOnline,
      busyOrderId: clearBusyOrder ? null : (busyOrderId ?? this.busyOrderId),
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
        orders,
        riderId,
        isOnline,
        busyOrderId,
        successMessage,
        errorMessage,
      ];
}
