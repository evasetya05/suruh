import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/usecases/order_usecases.dart';

part 'orders_state.dart';

/// Order history, split into active and past.
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit({required GetOrderHistory getOrderHistory})
      : _getOrderHistory = getOrderHistory,
        super(const OrdersState());

  final GetOrderHistory _getOrderHistory;

  Future<void> load(String userId, {bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: OrdersStatus.loading));

    final Result<List<Order>> result = await _getOrderHistory(userId);
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: OrdersStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (List<Order> orders) {
        final List<Order> sorted = List<Order>.of(orders)
          ..sort((Order a, Order b) => b.placedAt.compareTo(a.placedAt));
        emit(
          state.copyWith(
            status: OrdersStatus.success,
            orders: sorted,
            clearError: true,
          ),
        );
      },
    );
  }
}
