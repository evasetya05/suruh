import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/domain/entities/cart.dart';
import 'package:food_delivery_app/domain/entities/food_item.dart';
import 'package:food_delivery_app/domain/entities/promo.dart';

/// Cart maths is the highest-risk pure logic in the app - every fee, discount
/// and total the customer is charged comes from here.
void main() {
  FoodItem dish({
    String id = 'f-1',
    double price = 10,
    double? discount,
  }) =>
      FoodItem(
        id: id,
        restaurantId: 'r-1',
        restaurantName: 'Test Kitchen',
        name: 'Test dish $id',
        description: 'A dish',
        priceMyr: price,
        discountPriceMyr: discount,
        categoryId: 'malaysian',
        emoji: '🍛',
        rating: 4.5,
        reviewCount: 10,
      );

  Cart cartWith(
    List<CartItem> lines, {
    double deliveryFee = 5,
    double minOrder = 20,
    Promo? promo,
  }) =>
      Cart(
        restaurantId: 'r-1',
        restaurantName: 'Test Kitchen',
        deliveryFeeMyr: deliveryFee,
        minOrderMyr: minOrder,
        lines: lines,
        appliedPromo: promo,
      );

  group('Cart totals', () {
    test('an empty cart is zero across the board', () {
      const Cart cart = Cart.empty;

      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0);
      expect(cart.total, 0);
    });

    test('subtotal multiplies price by quantity across lines', () {
      final Cart cart = cartWith(<CartItem>[
        CartItem(item: dish(price: 10), quantity: 2),
        CartItem(item: dish(id: 'f-2', price: 5.50), quantity: 3),
      ]);

      expect(cart.itemCount, 5);
      expect(cart.subtotal, closeTo(36.50, 0.001));
    });

    test('a discounted dish is charged at its offer price', () {
      final Cart cart = cartWith(<CartItem>[
        CartItem(item: dish(price: 12.90, discount: 9.90), quantity: 2),
      ]);

      expect(cart.subtotal, closeTo(19.80, 0.001));
      expect(cart.itemSavings, closeTo(6.00, 0.001));
    });

    test('service fee is 10% of subtotal and caps at RM 3', () {
      final Cart small = cartWith(<CartItem>[
        CartItem(item: dish(price: 10), quantity: 1),
      ]);
      final Cart large = cartWith(<CartItem>[
        CartItem(item: dish(price: 100), quantity: 1),
      ]);

      expect(small.serviceFee, closeTo(1.00, 0.001));
      expect(large.serviceFee, PricingPolicy.serviceFeeCap);
    });

    test('a basket under the minimum picks up a small order fee', () {
      final Cart cart = cartWith(
        <CartItem>[CartItem(item: dish(price: 10), quantity: 1)],
        minOrder: 20,
      );

      expect(cart.isBelowMinimum, isTrue);
      expect(cart.smallOrderFee, PricingPolicy.smallOrderFee);
      expect(cart.amountToMinimum, closeTo(10, 0.001));
    });

    test('clearing the minimum removes the small order fee', () {
      final Cart cart = cartWith(
        <CartItem>[CartItem(item: dish(price: 25), quantity: 1)],
        minOrder: 20,
      );

      expect(cart.isBelowMinimum, isFalse);
      expect(cart.smallOrderFee, 0);
    });

    test('total sums subtotal, delivery, service and small order fees', () {
      final Cart cart = cartWith(
        <CartItem>[CartItem(item: dish(price: 30), quantity: 1)],
        deliveryFee: 5,
        minOrder: 20,
      );

      // 30 subtotal + 5 delivery + 3 capped service fee + 0 small order fee
      expect(cart.total, closeTo(38, 0.001));
    });
  });

  group('Promo codes', () {
    final Promo promo = Promo(
      id: 'p-1',
      code: 'SAVE30',
      title: '30% off',
      subtitle: 'Up to RM 12',
      discountPercent: 30,
      maxDiscountMyr: 12,
      minSpendMyr: 25,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );

    test('discount applies once the minimum spend is met', () {
      final Cart cart = cartWith(
        <CartItem>[CartItem(item: dish(price: 30), quantity: 1)],
        promo: promo,
      );

      expect(cart.promoDiscount, closeTo(9, 0.001));
    });

    test('discount is capped at the promo maximum', () {
      final Cart cart = cartWith(
        <CartItem>[CartItem(item: dish(price: 100), quantity: 1)],
        promo: promo,
      );

      expect(cart.promoDiscount, promo.maxDiscountMyr);
    });

    test('below the minimum spend the promo contributes nothing', () {
      final Cart cart = cartWith(
        <CartItem>[CartItem(item: dish(price: 10), quantity: 1)],
        promo: promo,
      );

      expect(promo.isEligibleFor(cart.subtotal), isFalse);
      expect(cart.promoDiscount, 0);
    });

    test('an expired promo never discounts', () {
      final Promo expired = Promo(
        id: 'p-2',
        code: 'OLD',
        title: 'Expired',
        subtitle: '',
        discountPercent: 50,
        maxDiscountMyr: 20,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(expired.isExpired, isTrue);
      expect(expired.discountFor(100), 0);
    });

    test('total never drops below zero, however large the discount', () {
      const Promo huge = Promo(
        id: 'p-3',
        code: 'FREE',
        title: 'Everything free',
        subtitle: '',
        discountPercent: 100,
        maxDiscountMyr: 9999,
      );
      final Cart cart = cartWith(
        <CartItem>[CartItem(item: dish(price: 10), quantity: 1)],
        deliveryFee: 0,
        minOrder: 0,
        promo: huge,
      );

      expect(cart.total, greaterThanOrEqualTo(0));
    });
  });

  group('Cart line identity', () {
    test('the same dish with different notes forms separate lines', () {
      final CartItem plain = CartItem(item: dish(), quantity: 1);
      final CartItem noChilli =
          CartItem(item: dish(), quantity: 1, notes: 'no chilli');

      expect(plain.lineId, isNot(noChilli.lineId));
    });

    test('quantityOf sums every line holding that dish', () {
      final Cart cart = cartWith(<CartItem>[
        CartItem(item: dish(), quantity: 2),
        CartItem(item: dish(), quantity: 3, notes: 'extra sauce'),
      ]);

      expect(cart.quantityOf('f-1'), 5);
    });

    test('a cart is locked to a single restaurant', () {
      final Cart cart = cartWith(<CartItem>[
        CartItem(item: dish(), quantity: 1),
      ]);

      expect(cart.belongsTo('r-1'), isTrue);
      expect(cart.belongsTo('r-2'), isFalse);
      expect(Cart.empty.belongsTo('anything'), isTrue);
    });
  });
}
