import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/usecases/order_usecases.dart';

part 'order_tracking_state.dart';

/// Live order tracking.
///
/// Loads once for the initial paint, then subscribes to the order stream so the
/// timeline advances on its own as the backend (or the demo simulation) moves
/// the order forward.
class OrderTrackingCubit extends Cubit<OrderTrackingState> {
  OrderTrackingCubit({
    required GetOrderById getOrderById,
    required WatchOrder watchOrder,
    required CancelOrder cancelOrder,
  })  : _getOrderById = getOrderById,
        _watchOrder = watchOrder,
        _cancelOrder = cancelOrder,
        super(const OrderTrackingState());

  final GetOrderById _getOrderById;
  final WatchOrder _watchOrder;
  final CancelOrder _cancelOrder;

  StreamSubscription<Order>? _subscription;

  Future<void> track(String orderId) async {
    emit(state.copyWith(status: OrderTrackingStatus.loading));

    final Result<Order> result = await _getOrderById(orderId);
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: OrderTrackingStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (Order order) => emit(
        state.copyWith(
          status: OrderTrackingStatus.success,
          order: order,
          clearError: true,
        ),
      ),
    );

    await _subscription?.cancel();
    _subscription = _watchOrder(orderId).listen(
      (Order order) {
        if (isClosed) return;
        emit(
          state.copyWith(status: OrderTrackingStatus.success, order: order),
        );
      },
      onError: (Object error) {
        if (isClosed) return;
        emit(
          state.copyWith(
            errorMessage: 'Live updates were interrupted. Pull to refresh.',
          ),
        );
      },
    );
  }

  Future<void> cancel(String orderId) async {
    emit(state.copyWith(isCancelling: true, clearError: true));
    final Result<Order> result = await _cancelOrder(orderId);
    result.fold(
      (Failure failure) => emit(
        state.copyWith(isCancelling: false, errorMessage: failure.message),
      ),
      (Order order) =>
          emit(state.copyWith(isCancelling: false, order: order)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
