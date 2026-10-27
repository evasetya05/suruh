part of 'cart_bloc.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the persisted basket at app start.
class CartStarted extends CartEvent {
  const CartStarted();
}

class CartItemAdded extends CartEvent {
  const CartItemAdded({
    required this.item,
    required this.restaurant,
    this.quantity = 1,
    this.notes = '',
  });

  final FoodItem item;
  final Restaurant restaurant;
  final int quantity;
  final String notes;

  @override
  List<Object?> get props => <Object?>[item, restaurant, quantity, notes];
}

class CartQuantityChanged extends CartEvent {
  const CartQuantityChanged({required this.lineId, required this.quantity});

  final String lineId;

  /// Zero removes the line.
  final int quantity;

  @override
  List<Object?> get props => <Object?>[lineId, quantity];
}

class CartLineRemoved extends CartEvent {
  const CartLineRemoved(this.lineId);

  final String lineId;

  @override
  List<Object?> get props => <Object?>[lineId];
}

class CartCleared extends CartEvent {
  const CartCleared();
}

class CartPromoApplied extends CartEvent {
  const CartPromoApplied(this.code);

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}

class CartPromoRemoved extends CartEvent {
  const CartPromoRemoved();
}

/// Dismisses the current snackbar message or restaurant-conflict prompt.
class CartFeedbackCleared extends CartEvent {
  const CartFeedbackCleared();
}
