import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/repositories/partner_repository.dart';
import '../../../domain/usecases/order_usecases.dart';
import '../../../domain/usecases/partner_usecases.dart';

part 'partner_event.dart';
part 'partner_state.dart';

/// The restaurant partner side: dashboard stats, live order queues and menu
/// management.
///
/// Orders arrive through a stream rather than polling, so an order placed on
/// the customer side shows up in the partner's "Incoming" queue within the same
/// frame the demo backend emits it.
class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  PartnerBloc({
    required GetPartnerDashboard getDashboard,
    required WatchRestaurantOrders watchOrders,
    required UpdateOrderStatus updateOrderStatus,
    required CreateMenuItem createMenuItem,
    required UpdateMenuItem updateMenuItem,
    required DeleteMenuItem deleteMenuItem,
    required SetItemAvailability setAvailability,
    required SetRestaurantOpen setRestaurantOpen,
  })  : _getDashboard = getDashboard,
        _watchOrders = watchOrders,
        _updateOrderStatus = updateOrderStatus,
        _createMenuItem = createMenuItem,
        _updateMenuItem = updateMenuItem,
        _deleteMenuItem = deleteMenuItem,
        _setAvailability = setAvailability,
        _setRestaurantOpen = setRestaurantOpen,
        super(const PartnerState()) {
    on<PartnerStarted>(_onStarted);
    on<PartnerOrdersUpdated>(_onOrdersUpdated);
    on<PartnerOrderAdvanced>(_onOrderAdvanced);
    on<PartnerMenuItemCreated>(_onMenuItemCreated);
    on<PartnerMenuItemUpdated>(_onMenuItemUpdated);
    on<PartnerMenuItemDeleted>(_onMenuItemDeleted);
    on<PartnerAvailabilityToggled>(_onAvailabilityToggled);
    on<PartnerStoreToggled>(_onStoreToggled);
    on<PartnerMessageCleared>(_onMessageCleared);
  }

  final GetPartnerDashboard _getDashboard;
  final WatchRestaurantOrders _watchOrders;
  final UpdateOrderStatus _updateOrderStatus;
  final CreateMenuItem _createMenuItem;
  final UpdateMenuItem _updateMenuItem;
  final DeleteMenuItem _deleteMenuItem;
  final SetItemAvailability _setAvailability;
  final SetRestaurantOpen _setRestaurantOpen;

  StreamSubscription<List<Order>>? _orderSubscription;

  Future<void> _onStarted(
    PartnerStarted event,
    Emitter<PartnerState> emit,
  ) async {
    emit(state.copyWith(status: PartnerStatus.loading));

    final Result<PartnerDashboard> result = await _getDashboard(event.ownerId);
    if (result.failureOrNull case final Failure failure) {
      emit(
        state.copyWith(
          status: PartnerStatus.failure,
          errorMessage: failure.message,
        ),
      );
      return;
    }

    final PartnerDashboard dashboard = result.valueOrNull!;
    emit(
      state.copyWith(
        status: PartnerStatus.success,
        restaurant: dashboard.restaurant,
        stats: dashboard.stats,
        menu: dashboard.menu,
        clearError: true,
      ),
    );

    await _orderSubscription?.cancel();
    _orderSubscription = _watchOrders(dashboard.restaurant.id).listen(
      (List<Order> orders) => add(PartnerOrdersUpdated(orders)),
    );
  }

  void _onOrdersUpdated(
    PartnerOrdersUpdated event,
    Emitter<PartnerState> emit,
  ) {
    final List<Order> sorted = List<Order>.of(event.orders)
      ..sort((Order a, Order b) => b.placedAt.compareTo(a.placedAt));
    emit(state.copyWith(orders: sorted));
  }

  Future<void> _onOrderAdvanced(
    PartnerOrderAdvanced event,
    Emitter<PartnerState> emit,
  ) async {
    emit(state.copyWith(busyOrderId: event.orderId));

    final Result<Order> result = await _updateOrderStatus(
      UpdateOrderStatusParams(orderId: event.orderId, status: event.status),
    );

    result.fold(
      (Failure failure) => emit(
        state.copyWith(clearBusyOrder: true, errorMessage: failure.message),
      ),
      (Order order) => emit(
        state.copyWith(
          clearBusyOrder: true,
          successMessage: 'Order ${order.id} → ${order.status.label}',
        ),
      ),
    );
  }

  Future<void> _onMenuItemCreated(
    PartnerMenuItemCreated event,
    Emitter<PartnerState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));

    final Result<FoodItem> result = await _createMenuItem(event.params);
    result.fold(
      (Failure failure) =>
          emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
      (FoodItem item) => emit(
        state.copyWith(
          isSaving: false,
          menu: <FoodItem>[...state.menu, item],
          successMessage: '${item.name} added to your menu',
        ),
      ),
    );
  }

  Future<void> _onMenuItemUpdated(
    PartnerMenuItemUpdated event,
    Emitter<PartnerState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));

    final Result<FoodItem> result = await _updateMenuItem(event.item);
    result.fold(
      (Failure failure) =>
          emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
      (FoodItem item) => emit(
        state.copyWith(
          isSaving: false,
          menu: _replaceInMenu(item),
          successMessage: '${item.name} updated',
        ),
      ),
    );
  }

  Future<void> _onMenuItemDeleted(
    PartnerMenuItemDeleted event,
    Emitter<PartnerState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearMessages: true));

    final Result<void> result = await _deleteMenuItem(event.foodItemId);
    result.fold(
      (Failure failure) =>
          emit(state.copyWith(isSaving: false, errorMessage: failure.message)),
      (_) => emit(
        state.copyWith(
          isSaving: false,
          menu: state.menu
              .where((FoodItem i) => i.id != event.foodItemId)
              .toList(growable: false),
          successMessage: 'Dish removed from your menu',
        ),
      ),
    );
  }

  Future<void> _onAvailabilityToggled(
    PartnerAvailabilityToggled event,
    Emitter<PartnerState> emit,
  ) async {
    // Optimistic so the switch does not lag behind the finger.
    emit(
      state.copyWith(
        menu: state.menu
            .map(
              (FoodItem i) => i.id == event.foodItemId
                  ? i.copyWith(isAvailable: event.isAvailable)
                  : i,
            )
            .toList(growable: false),
      ),
    );

    final Result<FoodItem> result = await _setAvailability(
      SetItemAvailabilityParams(
        foodItemId: event.foodItemId,
        isAvailable: event.isAvailable,
      ),
    );

    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          // Revert the optimistic flip.
          menu: state.menu
              .map(
                (FoodItem i) => i.id == event.foodItemId
                    ? i.copyWith(isAvailable: !event.isAvailable)
                    : i,
              )
              .toList(growable: false),
          errorMessage: failure.message,
        ),
      ),
      (FoodItem item) => emit(state.copyWith(menu: _replaceInMenu(item))),
    );
  }

  Future<void> _onStoreToggled(
    PartnerStoreToggled event,
    Emitter<PartnerState> emit,
  ) async {
    final Restaurant? restaurant = state.restaurant;
    if (restaurant == null) return;

    final Result<Restaurant> result = await _setRestaurantOpen(
      SetRestaurantOpenParams(
        restaurantId: restaurant.id,
        isOpen: event.isOpen,
      ),
    );

    result.fold(
      (Failure failure) => emit(state.copyWith(errorMessage: failure.message)),
      (Restaurant updated) => emit(
        state.copyWith(
          restaurant: updated,
          successMessage: updated.isOpen
              ? 'You are open for orders'
              : 'Storefront closed - no new orders will arrive',
        ),
      ),
    );
  }

  void _onMessageCleared(
    PartnerMessageCleared event,
    Emitter<PartnerState> emit,
  ) {
    emit(state.copyWith(clearMessages: true));
  }

  List<FoodItem> _replaceInMenu(FoodItem item) => state.menu
      .map((FoodItem i) => i.id == item.id ? item : i)
      .toList(growable: false);

  @override
  Future<void> close() async {
    await _orderSubscription?.cancel();
    return super.close();
  }
}
