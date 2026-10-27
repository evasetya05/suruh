import 'package:equatable/equatable.dart';

import 'food_item.dart';
import 'promo.dart';

/// A single line in the cart. Identity is the dish plus its customisation, so
/// "Nasi Lemak (no chilli)" and "Nasi Lemak" are two separate lines.
class CartItem extends Equatable {
  const CartItem({
    required this.item,
    required this.quantity,
    this.notes = '',
  });

  final FoodItem item;
  final int quantity;
  final String notes;

  /// Stable key used for add/remove/update operations.
  String get lineId => '${item.id}#${notes.hashCode}';

  double get lineTotal => item.effectivePrice * quantity;

  /// What the line would cost without any dish-level discount, used to show
  /// strike-through savings.
  double get lineListTotal => item.priceMyr * quantity;

  CartItem copyWith({int? quantity, String? notes}) => CartItem(
        item: item,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => <Object?>[item.id, quantity, notes];
}

/// Fee rules, kept in the domain so pricing is testable without any UI and
/// identical across customer checkout and partner order views.
abstract final class PricingPolicy {
  /// Platform service fee: 10% of subtotal, capped.
  static const double serviceFeeRate = 0.10;
  static const double serviceFeeCap = 3;

  /// Charged when the basket is below the restaurant's minimum.
  static const double smallOrderFee = 2;

  static double serviceFeeFor(double subtotal) =>
      (subtotal * serviceFeeRate).clamp(0, serviceFeeCap);
}

/// The customer's basket.
///
/// A cart belongs to exactly one restaurant - adding a dish from a different
/// restaurant requires clearing it first, which mirrors how Grab behaves.
class Cart extends Equatable {
  const Cart({
    this.restaurantId,
    this.restaurantName = '',
    this.deliveryFeeMyr = 0,
    this.minOrderMyr = 0,
    this.lines = const <CartItem>[],
    this.appliedPromo,
  });

  static const Cart empty = Cart();

  final String? restaurantId;
  final String restaurantName;
  final double deliveryFeeMyr;
  final double minOrderMyr;
  final List<CartItem> lines;
  final Promo? appliedPromo;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  int get itemCount =>
      lines.fold(0, (int sum, CartItem line) => sum + line.quantity);

  double get subtotal => lines.fold<double>(
        0,
        (double sum, CartItem line) => sum + line.lineTotal,
      );

  /// Savings from dish-level discounts (before any promo code).
  double get itemSavings =>
      lines.fold<double>(0, (double sum, CartItem l) => sum + l.lineListTotal) -
      subtotal;

  double get serviceFee => PricingPolicy.serviceFeeFor(subtotal);

  bool get isBelowMinimum => subtotal < minOrderMyr;

  double get smallOrderFee =>
      isBelowMinimum && isNotEmpty ? PricingPolicy.smallOrderFee : 0;

  double get promoDiscount => appliedPromo?.discountFor(subtotal) ?? 0;

  double get total {
    final double value =
        subtotal + deliveryFeeMyr + serviceFee + smallOrderFee - promoDiscount;
    return value < 0 ? 0 : value;
  }

  /// How much more is needed to clear the restaurant's minimum order.
  double get amountToMinimum =>
      isBelowMinimum ? (minOrderMyr - subtotal) : 0;

  int quantityOf(String foodItemId) => lines
      .where((CartItem l) => l.item.id == foodItemId)
      .fold(0, (int sum, CartItem l) => sum + l.quantity);

  bool belongsTo(String otherRestaurantId) =>
      restaurantId == null || restaurantId == otherRestaurantId;

  Cart copyWith({
    String? restaurantId,
    String? restaurantName,
    double? deliveryFeeMyr,
    double? minOrderMyr,
    List<CartItem>? lines,
    Promo? appliedPromo,
    bool clearPromo = false,
  }) {
    return Cart(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      deliveryFeeMyr: deliveryFeeMyr ?? this.deliveryFeeMyr,
      minOrderMyr: minOrderMyr ?? this.minOrderMyr,
      lines: lines ?? this.lines,
      appliedPromo: clearPromo ? null : (appliedPromo ?? this.appliedPromo),
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[restaurantId, lines, deliveryFeeMyr, minOrderMyr, appliedPromo];
}
