import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/error/failures.dart';
import 'package:food_delivery_app/core/usecase/usecase.dart';
import 'package:food_delivery_app/core/utils/result.dart';
import 'package:food_delivery_app/domain/entities/address.dart';
import 'package:food_delivery_app/domain/entities/cart.dart';
import 'package:food_delivery_app/domain/entities/food_item.dart';
import 'package:food_delivery_app/domain/entities/restaurant.dart';
import 'package:food_delivery_app/domain/usecases/cart_usecases.dart';
import 'package:food_delivery_app/features/cart/bloc/cart_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoadCart extends Mock implements LoadCart {}

class _MockAddToCart extends Mock implements AddToCart {}

class _MockUpdateQuantity extends Mock implements UpdateCartQuantity {}

class _MockRemoveLine extends Mock implements RemoveCartLine {}

class _MockClearCart extends Mock implements ClearCart {}

class _MockApplyPromo extends Mock implements ApplyPromoCode {}

class _MockRemovePromo extends Mock implements RemovePromo {}

void main() {
  const Address address = Address(
    id: 'a-1',
    label: AddressLabel.other,
    line1: '1 Test Street',
    city: 'Kuala Lumpur',
    postcode: '50000',
    state: 'WP Kuala Lumpur',
  );

  const Restaurant restaurantA = Restaurant(
    id: 'r-1',
    name: 'Kitchen A',
    cuisines: <String>['Malaysian'],
    emoji: '🍛',
    rating: 4.5,
    reviewCount: 100,
    deliveryFeeMyr: 5,
    minOrderMyr: 20,
    etaMinMinutes: 20,
    etaMaxMinutes: 30,
    distanceKm: 1,
    address: address,
  );

  const Restaurant restaurantB = Restaurant(
    id: 'r-2',
    name: 'Kitchen B',
    cuisines: <String>['Thai'],
    emoji: '🍜',
    rating: 4.2,
    reviewCount: 50,
    deliveryFeeMyr: 3,
    minOrderMyr: 15,
    etaMinMinutes: 25,
    etaMaxMinutes: 40,
    distanceKm: 3,
    address: address,
  );

  const FoodItem dishA = FoodItem(
    id: 'f-1',
    restaurantId: 'r-1',
    restaurantName: 'Kitchen A',
    name: 'Nasi Lemak',
    description: 'Coconut rice',
    priceMyr: 12,
    categoryId: 'malaysian',
    emoji: '🍛',
    rating: 4.8,
    reviewCount: 200,
  );

  const FoodItem dishB = FoodItem(
    id: 'f-2',
    restaurantId: 'r-2',
    restaurantName: 'Kitchen B',
    name: 'Pad Thai',
    description: 'Rice noodles',
    priceMyr: 18,
    categoryId: 'thai',
    emoji: '🍜',
    rating: 4.4,
    reviewCount: 90,
  );

  const Cart cartWithA = Cart(
    restaurantId: 'r-1',
    restaurantName: 'Kitchen A',
    deliveryFeeMyr: 5,
    minOrderMyr: 20,
    lines: <CartItem>[CartItem(item: dishA, quantity: 1)],
  );

  late _MockLoadCart loadCart;
  late _MockAddToCart addToCart;
  late _MockUpdateQuantity updateQuantity;
  late _MockRemoveLine removeLine;
  late _MockClearCart clearCart;
  late _MockApplyPromo applyPromo;
  late _MockRemovePromo removePromo;

  CartBloc buildBloc() => CartBloc(
        loadCart: loadCart,
        addToCart: addToCart,
        updateQuantity: updateQuantity,
        removeLine: removeLine,
        clearCart: clearCart,
        applyPromo: applyPromo,
        removePromo: removePromo,
      );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const AddToCartParams(item: dishA, restaurant: restaurantA),
    );
    registerFallbackValue(
      const UpdateQuantityParams(lineId: 'x', quantity: 1),
    );
  });

  setUp(() {
    loadCart = _MockLoadCart();
    addToCart = _MockAddToCart();
    updateQuantity = _MockUpdateQuantity();
    removeLine = _MockRemoveLine();
    clearCart = _MockClearCart();
    applyPromo = _MockApplyPromo();
    removePromo = _MockRemovePromo();
  });

  group('CartStarted', () {
    blocTest<CartBloc, CartState>(
      'loads the persisted basket',
      setUp: () => when(() => loadCart(any()))
          .thenAnswer((_) async => const Result<Cart>.success(cartWithA)),
      build: buildBloc,
      act: (CartBloc bloc) => bloc.add(const CartStarted()),
      expect: () => <Matcher>[
        isA<CartState>()
            .having((CartState s) => s.status, 'status', CartStatus.loading),
        isA<CartState>()
            .having((CartState s) => s.cart, 'cart', cartWithA)
            .having((CartState s) => s.status, 'status', CartStatus.ready),
      ],
    );

    blocTest<CartBloc, CartState>(
      'surfaces a load failure without losing the ready status',
      setUp: () => when(() => loadCart(any())).thenAnswer(
        (_) async => const Result<Cart>.failure(CacheFailure('Corrupt cart')),
      ),
      build: buildBloc,
      act: (CartBloc bloc) => bloc.add(const CartStarted()),
      skip: 1,
      expect: () => <Matcher>[
        isA<CartState>()
            .having((CartState s) => s.errorMessage, 'error', 'Corrupt cart'),
      ],
    );
  });

  group('CartItemAdded', () {
    blocTest<CartBloc, CartState>(
      'adds a dish and reports it',
      setUp: () => when(() => addToCart(any()))
          .thenAnswer((_) async => const Result<Cart>.success(cartWithA)),
      build: buildBloc,
      act: (CartBloc bloc) => bloc.add(
        const CartItemAdded(item: dishA, restaurant: restaurantA),
      ),
      expect: () => <Matcher>[
        isA<CartState>()
            .having((CartState s) => s.status, 'status', CartStatus.mutating),
        isA<CartState>()
            .having((CartState s) => s.cart, 'cart', cartWithA)
            .having(
              (CartState s) => s.successMessage,
              'message',
              contains('Nasi Lemak'),
            ),
      ],
    );

    blocTest<CartBloc, CartState>(
      'raises a conflict instead of silently replacing another restaurant',
      setUp: () {
        when(() => loadCart(any()))
            .thenAnswer((_) async => const Result<Cart>.success(cartWithA));
        when(() => addToCart(any()))
            .thenAnswer((_) async => const Result<Cart>.success(cartWithA));
      },
      build: buildBloc,
      seed: () => const CartState(status: CartStatus.ready, cart: cartWithA),
      act: (CartBloc bloc) => bloc.add(
        const CartItemAdded(item: dishB, restaurant: restaurantB),
      ),
      expect: () => <Matcher>[
        isA<CartState>().having(
          (CartState s) => s.pendingConflict?.existingRestaurantName,
          'conflict',
          'Kitchen A',
        ),
      ],
      verify: (_) => verifyNever(() => addToCart(any())),
    );
  });

  group('CartCleared', () {
    blocTest<CartBloc, CartState>(
      'replays the blocked dish after the customer confirms a new basket',
      setUp: () {
        when(() => clearCart(any()))
            .thenAnswer((_) async => const Result<Cart>.success(Cart.empty));
        when(() => addToCart(any())).thenAnswer(
          (_) async => const Result<Cart>.success(
            Cart(
              restaurantId: 'r-2',
              restaurantName: 'Kitchen B',
              lines: <CartItem>[CartItem(item: dishB, quantity: 1)],
            ),
          ),
        );
      },
      build: buildBloc,
      seed: () => const CartState(
        status: CartStatus.ready,
        cart: cartWithA,
        pendingConflict: CartConflict(
          existingRestaurantName: 'Kitchen A',
          incoming: CartItemAdded(item: dishB, restaurant: restaurantB),
        ),
      ),
      act: (CartBloc bloc) => bloc.add(const CartCleared()),
      wait: const Duration(milliseconds: 50),
      verify: (CartBloc bloc) {
        verify(() => clearCart(any())).called(1);
        verify(() => addToCart(any())).called(1);
        expect(bloc.state.cart.restaurantId, 'r-2');
        expect(bloc.state.pendingConflict, isNull);
      },
    );
  });

  group('CartQuantityChanged', () {
    blocTest<CartBloc, CartState>(
      'delegates to the use case, which removes the line at zero',
      setUp: () => when(() => updateQuantity(any()))
          .thenAnswer((_) async => const Result<Cart>.success(Cart.empty)),
      build: buildBloc,
      seed: () => const CartState(status: CartStatus.ready, cart: cartWithA),
      act: (CartBloc bloc) => bloc.add(
        const CartQuantityChanged(lineId: 'f-1#0', quantity: 0),
      ),
      verify: (CartBloc bloc) {
        verify(() => updateQuantity(any())).called(1);
        expect(bloc.state.cart.isEmpty, isTrue);
      },
    );
  });

  group('Promo codes', () {
    blocTest<CartBloc, CartState>(
      'reports a rejected code without changing the cart',
      setUp: () => when(() => applyPromo(any())).thenAnswer(
        (_) async => const Result<Cart>.failure(
          ValidationFailure('"NOPE" is not a valid promo code.'),
        ),
      ),
      build: buildBloc,
      seed: () => const CartState(status: CartStatus.ready, cart: cartWithA),
      act: (CartBloc bloc) => bloc.add(const CartPromoApplied('NOPE')),
      skip: 1,
      expect: () => <Matcher>[
        isA<CartState>()
            .having(
              (CartState s) => s.errorMessage,
              'error',
              contains('not a valid promo code'),
            )
            .having((CartState s) => s.cart, 'cart unchanged', cartWithA),
      ],
    );
  });
}
