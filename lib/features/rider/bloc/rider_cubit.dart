import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/usecases/order_usecases.dart';

part 'rider_state.dart';

/// Delivery partner queue.
///
/// The rider sees jobs assigned to them plus unclaimed orders that are ready
/// for pickup, and advances each one through pickup and delivery.
class RiderCubit extends Cubit<RiderState> {
  RiderCubit({
    required WatchRiderOrders watchOrders,
    required UpdateOrderStatus updateStatus,
  })  : _watchOrders = watchOrders,
        _updateStatus = updateStatus,
        super(const RiderState());

  final WatchRiderOrders _watchOrders;
  final UpdateOrderStatus _updateStatus;

  StreamSubscription<List<Order>>? _subscription;

  /// Rider ids in the seed data are `rd-*` while the login account is `u-rider`,
  /// so the demo persona maps onto the first seeded rider.
  static const String demoRiderId = 'rd-01';

  Future<void> start({String riderId = demoRiderId}) async {
    emit(state.copyWith(status: RiderStatus.loading, riderId: riderId));

    await _subscription?.cancel();
    _subscription = _watchOrders(riderId).listen(
      (List<Order> orders) {
        if (isClosed) return;
        final List<Order> sorted = List<Order>.of(orders)
          ..sort((Order a, Order b) => b.placedAt.compareTo(a.placedAt));
        emit(
          state.copyWith(
            status: RiderStatus.success,
            orders: sorted,
            clearError: true,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(
          state.copyWith(
            status: RiderStatus.failure,
            errorMessage: 'Could not load your delivery queue.',
          ),
        );
      },
    );
  }

  Future<void> advance(String orderId, OrderStatus status) async {
    emit(state.copyWith(busyOrderId: orderId, clearMessages: true));

    final Result<Order> result = await _updateStatus(
      UpdateOrderStatusParams(orderId: orderId, status: status),
    );

    result.fold(
      (Failure failure) => emit(
        state.copyWith(clearBusyOrder: true, errorMessage: failure.message),
      ),
      (Order order) => emit(
        state.copyWith(
          clearBusyOrder: true,
          successMessage: order.status == OrderStatus.delivered
              ? 'Delivered. Nice work!'
              : 'Updated to ${order.status.label}',
        ),
      ),
    );
  }

  void setOnline({required bool isOnline}) =>
      emit(state.copyWith(isOnline: isOnline));

  void clearMessages() => emit(state.copyWith(clearMessages: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
