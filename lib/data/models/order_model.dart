import '../../domain/entities/order.dart';
import 'address_model.dart';
import 'cart_model.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.restaurantId,
    required super.restaurantName,
    required super.restaurantEmoji,
    required super.lines,
    required super.status,
    required super.placedAt,
    required super.deliveryAddress,
    required super.paymentMethod,
    required super.subtotal,
    required super.deliveryFee,
    required super.serviceFee,
    required super.discount,
    required super.total,
    super.customerName,
    super.customerPhone,
    super.rider,
    super.timeline,
    super.etaMinutes,
    super.deliveredAt,
    super.riderNote,
    super.isRated,
  });

  factory OrderModel.fromEntity(Order o) => OrderModel(
        id: o.id,
        userId: o.userId,
        restaurantId: o.restaurantId,
        restaurantName: o.restaurantName,
        restaurantEmoji: o.restaurantEmoji,
        lines: o.lines,
        status: o.status,
        placedAt: o.placedAt,
        deliveryAddress: o.deliveryAddress,
        paymentMethod: o.paymentMethod,
        subtotal: o.subtotal,
        deliveryFee: o.deliveryFee,
        serviceFee: o.serviceFee,
        discount: o.discount,
        total: o.total,
        customerName: o.customerName,
        customerPhone: o.customerPhone,
        rider: o.rider,
        timeline: o.timeline,
        etaMinutes: o.etaMinutes,
        deliveredAt: o.deliveredAt,
        riderNote: o.riderNote,
        isRated: o.isRated,
      );

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String,
        restaurantEmoji: json['restaurantEmoji'] as String? ?? '🍽️',
        lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                CartMapper.cartItemFromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        status: OrderStatus.fromName(json['status'] as String?),
        placedAt: DateTime.parse(json['placedAt'] as String),
        deliveryAddress: AddressModel.fromJson(
          json['deliveryAddress'] as Map<String, dynamic>,
        ),
        paymentMethod: PaymentMethod.fromName(json['paymentMethod'] as String?),
        subtotal: (json['subtotal'] as num).toDouble(),
        deliveryFee: (json['deliveryFee'] as num).toDouble(),
        serviceFee: (json['serviceFee'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num).toDouble(),
        customerName: json['customerName'] as String? ?? '',
        customerPhone: json['customerPhone'] as String? ?? '',
        rider: json['rider'] == null
            ? null
            : _riderFromJson(json['rider'] as Map<String, dynamic>),
        timeline: (json['timeline'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => _eventFromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        etaMinutes: json['etaMinutes'] as int? ?? 30,
        deliveredAt: json['deliveredAt'] == null
            ? null
            : DateTime.tryParse(json['deliveredAt'] as String),
        riderNote: json['riderNote'] as String?,
        isRated: json['isRated'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'restaurantEmoji': restaurantEmoji,
        'lines': lines.map(CartMapper.cartItemToJson).toList(growable: false),
        'status': status.name,
        'placedAt': placedAt.toIso8601String(),
        'deliveryAddress':
            AddressModel.fromEntity(deliveryAddress).toJson(),
        'paymentMethod': paymentMethod.name,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'serviceFee': serviceFee,
        'discount': discount,
        'total': total,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'rider': rider == null ? null : _riderToJson(rider!),
        'timeline': timeline.map(_eventToJson).toList(growable: false),
        'etaMinutes': etaMinutes,
        'deliveredAt': deliveredAt?.toIso8601String(),
        'riderNote': riderNote,
        'isRated': isRated,
      };

  static Map<String, dynamic> _riderToJson(DeliveryRider r) =>
      <String, dynamic>{
        'id': r.id,
        'name': r.name,
        'vehicle': r.vehicle,
        'plateNumber': r.plateNumber,
        'rating': r.rating,
        'avatarEmoji': r.avatarEmoji,
        'phone': r.phone,
      };

  static DeliveryRider _riderFromJson(Map<String, dynamic> json) =>
      DeliveryRider(
        id: json['id'] as String,
        name: json['name'] as String,
        vehicle: json['vehicle'] as String? ?? 'Motorcycle',
        plateNumber: json['plateNumber'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 5,
        avatarEmoji: json['avatarEmoji'] as String? ?? '🛵',
        phone: json['phone'] as String? ?? '',
      );

  static Map<String, dynamic> _eventToJson(OrderEvent e) => <String, dynamic>{
        'status': e.status.name,
        'at': e.at.toIso8601String(),
        'note': e.note,
      };

  static OrderEvent _eventFromJson(Map<String, dynamic> json) => OrderEvent(
        status: OrderStatus.fromName(json['status'] as String?),
        at: DateTime.parse(json['at'] as String),
        note: json['note'] as String?,
      );
}
