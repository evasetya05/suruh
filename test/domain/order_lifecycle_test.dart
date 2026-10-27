import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/domain/entities/address.dart';
import 'package:food_delivery_app/domain/entities/order.dart';

/// The order status machine drives the customer timeline, the partner's
/// "next action" button and the rider queue, so its transitions are pinned here.
void main() {
  const Address address = Address(
    id: 'a-1',
    label: AddressLabel.home,
    line1: '1 Test Street',
    city: 'Kuala Lumpur',
    postcode: '50000',
    state: 'WP Kuala Lumpur',
  );

  Order order({OrderStatus status = OrderStatus.placed}) => Order(
        id: 'o-1',
        userId: 'u-1',
        restaurantId: 'r-1',
        restaurantName: 'Test Kitchen',
        restaurantEmoji: '🍛',
        lines: const <dynamic>[].cast(),
        status: status,
        placedAt: DateTime(2026, 7, 31, 12),
        deliveryAddress: address,
        paymentMethod: PaymentMethod.grabPay,
        subtotal: 30,
        deliveryFee: 5,
        serviceFee: 3,
        discount: 0,
        total: 38,
      );

  group('Status transitions', () {
    test('walks the happy path in order and then stops', () {
      OrderStatus? status = OrderStatus.placed;
      final List<OrderStatus> path = <OrderStatus>[status];

      while ((status = status!.next) != null) {
        path.add(status!);
      }

      expect(path, <OrderStatus>[
        OrderStatus.placed,
        OrderStatus.confirmed,
        OrderStatus.preparing,
        OrderStatus.readyForPickup,
        OrderStatus.outForDelivery,
        OrderStatus.delivered,
      ]);
    });

    test('terminal states have no next step', () {
      expect(OrderStatus.delivered.next, isNull);
      expect(OrderStatus.cancelled.next, isNull);
      expect(OrderStatus.delivered.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
      expect(OrderStatus.preparing.isTerminal, isFalse);
    });

    test('advanceTo appends a timeline entry and moves the status', () {
      final Order advanced = order().advanceTo(OrderStatus.confirmed);

      expect(advanced.status, OrderStatus.confirmed);
      expect(advanced.timeline, hasLength(1));
      expect(advanced.timeline.single.status, OrderStatus.confirmed);
    });

    test('delivering stamps deliveredAt', () {
      final Order delivered = order(status: OrderStatus.outForDelivery)
          .advanceTo(OrderStatus.delivered);

      expect(delivered.deliveredAt, isNotNull);
    });

    test('a cancellation note is preserved on the timeline', () {
      final Order cancelled = order().advanceTo(
        OrderStatus.cancelled,
        note: 'Restaurant closed',
      );

      expect(cancelled.status, OrderStatus.cancelled);
      expect(cancelled.timeline.single.note, 'Restaurant closed');
      expect(cancelled.isActive, isFalse);
    });
  });

  group('Tracking progress', () {
    test('maps each status onto a quarter of the timeline', () {
      expect(order().trackingProgress, closeTo(0.25, 0.001));
      expect(
        order(status: OrderStatus.preparing).trackingProgress,
        closeTo(0.5, 0.001),
      );
      expect(
        order(status: OrderStatus.outForDelivery).trackingProgress,
        closeTo(0.75, 0.001),
      );
      expect(
        order(status: OrderStatus.delivered).trackingProgress,
        closeTo(1.0, 0.001),
      );
    });

    test('a cancelled order shows no progress', () {
      expect(order(status: OrderStatus.cancelled).trackingProgress, 0);
    });

    test('readyForPickup shares the preparing stage', () {
      expect(
        order(status: OrderStatus.readyForPickup).trackingProgress,
        order(status: OrderStatus.preparing).trackingProgress,
      );
    });
  });

  group('Estimated arrival', () {
    test('is the placement time plus the ETA', () {
      final Order o = order();
      expect(
        o.estimatedArrival,
        o.placedAt.add(Duration(minutes: o.etaMinutes)),
      );
    });
  });
}
