import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/error/failures.dart';
import 'package:food_delivery_app/core/utils/result.dart';
import 'package:food_delivery_app/domain/entities/address.dart';
import 'package:food_delivery_app/domain/entities/cart.dart';
import 'package:food_delivery_app/domain/entities/order.dart';
import 'package:food_delivery_app/domain/usecases/order_usecases.dart';
import 'package:food_delivery_app/features/orders/bloc/orders_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetOrderHistory extends Mock implements GetOrderHistory {}

void main() {
  const Address address = Address(
    id: 'a-1',
    label: AddressLabel.home,
    line1: '1 Test Street',
    city: 'Kuala Lumpur',
    postcode: '50000',
    state: 'WP Kuala Lumpur',
  );

  Order orderAt(String id, DateTime placedAt, OrderStatus status) => Order(
        id: id,
        userId: 'u-1',
        restaurantId: 'r-1',
        restaurantName: 'Kitchen A',
        restaurantEmoji: '🍛',
        lines: const <CartItem>[],
        status: status,
        placedAt: placedAt,
        deliveryAddress: address,
        paymentMethod: PaymentMethod.cash,
        subtotal: 20,
        deliveryFee: 5,
        serviceFee: 2,
        discount: 0,
        total: 27,
      );

  final Order older =
      orderAt('o-1', DateTime(2026, 1, 1), OrderStatus.delivered);
  final Order newer =
      orderAt('o-2', DateTime(2026, 2, 1), OrderStatus.preparing);

  late _MockGetOrderHistory getOrderHistory;

  setUp(() => getOrderHistory = _MockGetOrderHistory());

  OrdersCubit buildCubit() => OrdersCubit(getOrderHistory: getOrderHistory);

  group('load', () {
    blocTest<OrdersCubit, OrdersState>(
      'emits loading, then the history newest first',
      setUp: () => when(() => getOrderHistory(any())).thenAnswer(
        (_) async => Result<List<Order>>.success(<Order>[older, newer]),
      ),
      build: buildCubit,
      act: (OrdersCubit cubit) => cubit.load('u-1'),
      expect: () => <Matcher>[
        isA<OrdersState>()
            .having((OrdersState s) => s.status, 'status', OrdersStatus.loading),
        isA<OrdersState>()
            .having((OrdersState s) => s.status, 'status', OrdersStatus.success)
            .having((OrdersState s) => s.orders.first.id, 'newest first', 'o-2'),
      ],
    );

    blocTest<OrdersCubit, OrdersState>(
      'splits active from past so the tabs do not have to',
      setUp: () => when(() => getOrderHistory(any())).thenAnswer(
        (_) async => Result<List<Order>>.success(<Order>[older, newer]),
      ),
      build: buildCubit,
      act: (OrdersCubit cubit) => cubit.load('u-1'),
      skip: 1,
      expect: () => <Matcher>[
        isA<OrdersState>()
            .having((OrdersState s) => s.active.single.id, 'active', 'o-2')
            .having((OrdersState s) => s.past.single.id, 'past', 'o-1'),
      ],
    );

    blocTest<OrdersCubit, OrdersState>(
      'surfaces the failure message instead of throwing',
      setUp: () => when(() => getOrderHistory(any())).thenAnswer(
        (_) async => const Result<List<Order>>.failure(
          NetworkFailure('You are offline'),
        ),
      ),
      build: buildCubit,
      act: (OrdersCubit cubit) => cubit.load('u-1'),
      skip: 1,
      expect: () => <Matcher>[
        isA<OrdersState>()
            .having((OrdersState s) => s.status, 'status', OrdersStatus.failure)
            .having(
              (OrdersState s) => s.errorMessage,
              'errorMessage',
              'You are offline',
            ),
      ],
    );

    blocTest<OrdersCubit, OrdersState>(
      'silent refresh does not drop the screen back to skeletons',
      setUp: () => when(() => getOrderHistory(any())).thenAnswer(
        (_) async => Result<List<Order>>.success(<Order>[newer]),
      ),
      build: buildCubit,
      act: (OrdersCubit cubit) => cubit.load('u-1', silent: true),
      expect: () => <Matcher>[
        isA<OrdersState>()
            .having((OrdersState s) => s.status, 'status', OrdersStatus.success),
      ],
    );
  });
}
