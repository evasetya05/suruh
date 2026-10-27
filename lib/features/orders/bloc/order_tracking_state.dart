part of 'order_tracking_cubit.dart';

enum OrderTrackingStatus { initial, loading, success, failure }

class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.status = OrderTrackingStatus.initial,
    this.order,
    this.isCancelling = false,
    this.errorMessage,
  });

  final OrderTrackingStatus status;
  final Order? order;
  final bool isCancelling;
  final String? errorMessage;

  bool get isLoading =>
      status == OrderTrackingStatus.loading ||
      status == OrderTrackingStatus.initial;

  /// Cancellation is only offered before the kitchen starts cooking.
  bool get canCancel =>
      order != null &&
      (order!.status == OrderStatus.placed ||
          order!.status == OrderStatus.confirmed) &&
      !isCancelling;

  OrderTrackingState copyWith({
    OrderTrackingStatus? status,
    Order? order,
    bool? isCancelling,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderTrackingState(
      status: status ?? this.status,
      order: order ?? this.order,
      isCancelling: isCancelling ?? this.isCancelling,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, order, isCancelling, errorMessage];
}
