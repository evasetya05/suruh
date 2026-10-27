import 'package:equatable/equatable.dart';

import 'address.dart';
import 'cart.dart';

/// The lifecycle of an order, in progression order.
///
/// [index] ordering is meaningful: the tracking timeline and the partner
/// "advance status" action both rely on it.
enum OrderStatus {
  placed('Order placed', 'We sent your order to the restaurant', '🧾'),
  confirmed('Order confirmed', 'The restaurant accepted your order', '✅'),
  preparing('Preparing your food', 'Your meal is being cooked fresh', '👨‍🍳'),
  readyForPickup('Ready for pickup', 'Waiting for a rider to collect', '🛍️'),
  outForDelivery('Out for delivery', 'Your rider is on the way', '🛵'),
  delivered('Delivered', 'Enjoy your meal!', '🎉'),
  cancelled('Cancelled', 'This order was cancelled', '❌');

  const OrderStatus(this.label, this.description, this.emoji);

  final String label;
  final String description;
  final String emoji;

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  bool get isActive => !isTerminal;

  /// The four customer-facing tracking stages.
  static const List<OrderStatus> trackingStages = <OrderStatus>[
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  /// Next status in the happy path, or `null` at the end.
  OrderStatus? get next => switch (this) {
        OrderStatus.placed => OrderStatus.confirmed,
        OrderStatus.confirmed => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.readyForPickup,
        OrderStatus.readyForPickup => OrderStatus.outForDelivery,
        OrderStatus.outForDelivery => OrderStatus.delivered,
        OrderStatus.delivered || OrderStatus.cancelled => null,
      };

  static OrderStatus fromName(String? value) => OrderStatus.values.firstWhere(
        (OrderStatus s) => s.name == value,
        orElse: () => OrderStatus.placed,
      );
}

enum PaymentMethod {
  grabPay('GrabPay Wallet', '💚'),
  card('Credit / Debit card', '💳'),
  onlineBanking('Online banking (FPX)', '🏦'),
  cash('Cash on delivery', '💵');

  const PaymentMethod(this.label, this.emoji);
  final String label;
  final String emoji;

  static PaymentMethod fromName(String? value) =>
      PaymentMethod.values.firstWhere(
        (PaymentMethod m) => m.name == value,
        orElse: () => PaymentMethod.grabPay,
      );
}

/// One entry in the order's audit trail.
class OrderEvent extends Equatable {
  const OrderEvent({
    required this.status,
    required this.at,
    this.note,
  });

  final OrderStatus status;
  final DateTime at;
  final String? note;

  @override
  List<Object?> get props => <Object?>[status, at, note];
}

/// The rider assigned to an order.
class DeliveryRider extends Equatable {
  const DeliveryRider({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.plateNumber,
    required this.rating,
    this.avatarEmoji = '🛵',
    this.phone = '+60 12-000 0000',
  });

  final String id;
  final String name;
  final String vehicle;
  final String plateNumber;
  final double rating;
  final String avatarEmoji;
  final String phone;

  @override
  List<Object?> get props => <Object?>[id, name, plateNumber];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantEmoji,
    required this.lines,
    required this.status,
    required this.placedAt,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
    this.customerName = '',
    this.customerPhone = '',
    this.rider,
    this.timeline = const <OrderEvent>[],
    this.etaMinutes = 30,
    this.deliveredAt,
    this.riderNote,
    this.isRated = false,
  });

  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String restaurantEmoji;
  final List<CartItem> lines;
  final OrderStatus status;
  final DateTime placedAt;
  final Address deliveryAddress;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;
  final String customerName;
  final String customerPhone;
  final DeliveryRider? rider;
  final List<OrderEvent> timeline;
  final int etaMinutes;
  final DateTime? deliveredAt;
  final String? riderNote;
  final bool isRated;

  int get itemCount =>
      lines.fold(0, (int sum, CartItem l) => sum + l.quantity);

  /// `2x Nasi Lemak, 1x Teh Tarik`
  String get itemSummary =>
      lines.map((CartItem l) => '${l.quantity}x ${l.item.name}').join(', ');

  DateTime get estimatedArrival => placedAt.add(Duration(minutes: etaMinutes));

  /// 0.0 - 1.0 across the four customer-facing tracking stages.
  double get trackingProgress {
    if (status == OrderStatus.cancelled) return 0;
    final int stage = switch (status) {
      OrderStatus.placed || OrderStatus.confirmed => 1,
      OrderStatus.preparing || OrderStatus.readyForPickup => 2,
      OrderStatus.outForDelivery => 3,
      OrderStatus.delivered => 4,
      OrderStatus.cancelled => 0,
    };
    return stage / OrderStatus.trackingStages.length;
  }

  bool get isActive => status.isActive;

  Order copyWith({
    OrderStatus? status,
    DeliveryRider? rider,
    List<OrderEvent>? timeline,
    DateTime? deliveredAt,
    String? riderNote,
    bool? isRated,
    int? etaMinutes,
  }) {
    return Order(
      id: id,
      userId: userId,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantEmoji: restaurantEmoji,
      lines: lines,
      status: status ?? this.status,
      placedAt: placedAt,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      total: total,
      customerName: customerName,
      customerPhone: customerPhone,
      rider: rider ?? this.rider,
      timeline: timeline ?? this.timeline,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      riderNote: riderNote ?? this.riderNote,
      isRated: isRated ?? this.isRated,
    );
  }

  /// Appends a timeline entry and moves the order to [newStatus].
  Order advanceTo(OrderStatus newStatus, {String? note}) {
    return copyWith(
      status: newStatus,
      timeline: <OrderEvent>[
        ...timeline,
        OrderEvent(status: newStatus, at: DateTime.now(), note: note),
      ],
      deliveredAt: newStatus == OrderStatus.delivered ? DateTime.now() : null,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        userId,
        restaurantId,
        status,
        placedAt,
        total,
        lines,
        timeline,
        rider,
        isRated,
      ];
}
