part of 'cart_bloc.dart';

enum CartStatus { initial, loading, ready, mutating }

/// Raised when a dish from a different restaurant is added to a non-empty cart.
///
/// Carries the original event so the bloc can replay it once the customer
/// confirms starting a new basket.
class CartConflict extends Equatable {
  const CartConflict({
    required this.existingRestaurantName,
    required this.incoming,
  });

  final String existingRestaurantName;
  final CartItemAdded incoming;

  String get incomingRestaurantName => incoming.restaurant.name;

  @override
  List<Object?> get props => <Object?>[existingRestaurantName, incoming];
}

class CartState extends Equatable {
  const CartState({
    this.status = CartStatus.initial,
    this.cart = Cart.empty,
    this.successMessage,
    this.errorMessage,
    this.pendingConflict,
  });

  final CartStatus status;
  final Cart cart;
  final String? successMessage;
  final String? errorMessage;
  final CartConflict? pendingConflict;

  bool get isBusy =>
      status == CartStatus.loading || status == CartStatus.mutating;

  int get itemCount => cart.itemCount;

  /// Quantity of [foodItemId] currently in the basket, used to show a stepper
  /// instead of an "Add" button on menu rows.
  int quantityOf(String foodItemId) => cart.quantityOf(foodItemId);

  CartState copyWith({
    CartStatus? status,
    Cart? cart,
    String? successMessage,
    String? errorMessage,
    CartConflict? pendingConflict,
    bool clearFeedback = false,
    bool clearConflict = false,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      successMessage:
          clearFeedback ? null : (successMessage ?? this.successMessage),
      errorMessage: clearFeedback ? null : (errorMessage ?? this.errorMessage),
      pendingConflict:
          clearConflict ? null : (pendingConflict ?? this.pendingConflict),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        cart,
        successMessage,
        errorMessage,
        pendingConflict,
      ];
}
