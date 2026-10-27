import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/restaurant.dart';
import '../../../domain/usecases/cart_usecases.dart';

part 'cart_event.dart';
part 'cart_state.dart';

/// App-wide basket.
///
/// Lives above the router so the cart badge, the restaurant menu's "already in
/// cart" quantities and the checkout screen all read one source of truth.
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required LoadCart loadCart,
    required AddToCart addToCart,
    required UpdateCartQuantity updateQuantity,
    required RemoveCartLine removeLine,
    required ClearCart clearCart,
    required ApplyPromoCode applyPromo,
    required RemovePromo removePromo,
  })  : _loadCart = loadCart,
        _addToCart = addToCart,
        _updateQuantity = updateQuantity,
        _removeLine = removeLine,
        _clearCart = clearCart,
        _applyPromo = applyPromo,
        _removePromo = removePromo,
        super(const CartState()) {
    on<CartStarted>(_onStarted);
    on<CartItemAdded>(_onItemAdded);
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartLineRemoved>(_onLineRemoved);
    on<CartCleared>(_onCleared);
    on<CartPromoApplied>(_onPromoApplied);
    on<CartPromoRemoved>(_onPromoRemoved);
    on<CartFeedbackCleared>(_onFeedbackCleared);
  }

  final LoadCart _loadCart;
  final AddToCart _addToCart;
  final UpdateCartQuantity _updateQuantity;
  final RemoveCartLine _removeLine;
  final ClearCart _clearCart;
  final ApplyPromoCode _applyPromo;
  final RemovePromo _removePromo;

  Future<void> _onStarted(CartStarted event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.loading));
    final Result<Cart> result = await _loadCart(const NoParams());
    _emitCart(result, emit);
  }

  Future<void> _onItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    // If the basket belongs to another restaurant, surface a conflict instead
    // of silently discarding it - the UI turns this into a confirm dialog.
    if (state.cart.isNotEmpty && !state.cart.belongsTo(event.restaurant.id)) {
      emit(
        state.copyWith(
          pendingConflict: CartConflict(
            existingRestaurantName: state.cart.restaurantName,
            incoming: event,
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(status: CartStatus.mutating, clearFeedback: true));
    final Result<Cart> result = await _addToCart(
      AddToCartParams(
        item: event.item,
        restaurant: event.restaurant,
        quantity: event.quantity,
        notes: event.notes,
      ),
    );
    _emitCart(
      result,
      emit,
      successMessage: '${event.item.name} added to your cart',
    );
  }

  Future<void> _onQuantityChanged(
    CartQuantityChanged event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.mutating, clearFeedback: true));
    final Result<Cart> result = await _updateQuantity(
      UpdateQuantityParams(lineId: event.lineId, quantity: event.quantity),
    );
    _emitCart(result, emit);
  }

  Future<void> _onLineRemoved(
    CartLineRemoved event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.mutating, clearFeedback: true));
    final Result<Cart> result = await _removeLine(event.lineId);
    _emitCart(result, emit, successMessage: 'Item removed');
  }

  Future<void> _onCleared(CartCleared event, Emitter<CartState> emit) async {
    emit(state.copyWith(status: CartStatus.mutating, clearFeedback: true));
    final Result<Cart> result = await _clearCart(const NoParams());

    // A clear triggered by a restaurant conflict immediately re-adds the dish
    // the customer was actually trying to order.
    final CartConflict? conflict = state.pendingConflict;
    if (result.isSuccess && conflict != null) {
      emit(state.copyWith(cart: Cart.empty, clearConflict: true));
      add(conflict.incoming);
      return;
    }

    _emitCart(result, emit, successMessage: 'Cart cleared');
  }

  Future<void> _onPromoApplied(
    CartPromoApplied event,
    Emitter<CartState> emit,
  ) async {
    emit(state.copyWith(status: CartStatus.mutating, clearFeedback: true));
    final Result<Cart> result = await _applyPromo(event.code);
    _emitCart(
      result,
      emit,
      successMessage: 'Promo ${event.code.toUpperCase()} applied',
    );
  }

  Future<void> _onPromoRemoved(
    CartPromoRemoved event,
    Emitter<CartState> emit,
  ) async {
    final Result<Cart> result = await _removePromo(const NoParams());
    _emitCart(result, emit, successMessage: 'Promo removed');
  }

  void _onFeedbackCleared(
    CartFeedbackCleared event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(clearFeedback: true, clearConflict: true));
  }

  void _emitCart(
    Result<Cart> result,
    Emitter<CartState> emit, {
    String? successMessage,
  }) {
    result.fold(
      (Failure failure) => emit(
        state.copyWith(
          status: CartStatus.ready,
          errorMessage: failure.message,
        ),
      ),
      (Cart cart) => emit(
        state.copyWith(
          status: CartStatus.ready,
          cart: cart,
          successMessage: successMessage,
          clearConflict: true,
        ),
      ),
    );
  }
}
