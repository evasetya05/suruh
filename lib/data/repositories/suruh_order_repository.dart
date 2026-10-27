import 'dart:async';
import 'dart:developer' as developer;

import '../../core/network/suruh_api_client.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/local/demo_data_source.dart';
import '../models/order_model.dart';
import 'order_repository_impl.dart';

/// Order repository connected to the SURUH Django REST API (/api/v1/orders/).
class SuruhOrderRepository implements OrderRepository {
  SuruhOrderRepository({
    required SuruhApiClient api,
    required LocalStorage storage,
    required DemoDataSource fallbackSource,
  })  : _api = api,
        _storage = storage,
        _fallbackRepo = OrderRepositoryImpl(remote: fallbackSource);

  final SuruhApiClient _api;
  final LocalStorage _storage;
  final OrderRepositoryImpl _fallbackRepo;

  final Map<String, StreamController<Order>> _orderStreams =
      <String, StreamController<Order>>{};

  @override
  Future<Result<Order>> placeOrder({
    required Cart cart,
    required Address deliveryAddress,
    required PaymentMethod paymentMethod,
    required String userId,
    required String customerName,
    required String customerPhone,
    String? riderNote,
  }) {
    return guard<Order>(() async {
      final double totalAmount = cart.total;

      try {
        // Post order to real SURUH backend
        final Map<String, dynamic> response = await _api.createOrder(
          isCustomRequest: false,
          customRequestTitle: 'Pesanan SURUH - ${cart.restaurantName}',
          instructionData: <String, dynamic>{
            'items': cart.lines
                .map((CartItem l) => <String, dynamic>{
                      'name': l.item.name,
                      'quantity': l.quantity,
                      'unit_price': l.item.effectivePrice,
                      'notes': l.notes,
                    })
                .toList(),
            'payment_method': paymentMethod.name,
          },
          pickupData: <String, dynamic>{
            'address': 'Hub SURUH ${cart.restaurantName}',
            'detail': 'Kota Pontianak',
            'contact_name': cart.restaurantName,
            'contact_phone': '+62812000000',
          },
          destinationData: <String, dynamic>{
            'address': deliveryAddress.formatted,
            'detail': deliveryAddress.line2 ?? '',
            'contact_name': customerName,
            'contact_phone': customerPhone,
          },
          customerNote: riderNote,
          distanceKm: 2.5,
          quantity: cart.itemCount,
        );

        final String orderNumber = response['order_number'] as String? ??
            'SRH-${DateTime.now().millisecondsSinceEpoch}';

        final Order placed = Order(
          id: orderNumber,
          userId: userId,
          restaurantId: cart.restaurantId ?? 'prov-suruh',
          restaurantName: cart.restaurantName,
          restaurantEmoji: '⚡',
          lines: cart.lines,
          status: OrderStatus.placed,
          placedAt: DateTime.now(),
          deliveryAddress: deliveryAddress,
          paymentMethod: paymentMethod,
          subtotal: cart.subtotal,
          deliveryFee: cart.deliveryFeeMyr,
          serviceFee: cart.serviceFee + cart.smallOrderFee,
          discount: cart.promoDiscount,
          total: totalAmount,
          customerName: customerName,
          customerPhone: customerPhone,
          riderNote: riderNote,
          timeline: <OrderEvent>[
            OrderEvent(
              status: OrderStatus.placed,
              at: DateTime.now(),
              note: 'Pesanan terdaftar di sistem SURUH Pontianak',
            ),
          ],
        );

        await _saveOrderLocally(placed);
        _notifyOrderUpdate(placed);
        return placed;
      } catch (e) {
        developer.log(
          'Order create on backend failed: $e. Falling back to local queue.',
          name: 'SuruhOrderRepository',
        );
        // Fallback to local offline simulated order so user journey is never blocked
        return (await _fallbackRepo.placeOrder(
          cart: cart,
          deliveryAddress: deliveryAddress,
          paymentMethod: paymentMethod,
          userId: userId,
          customerName: customerName,
          customerPhone: customerPhone,
          riderNote: riderNote,
        )).fold(
          (failure) => throw failure,
          (order) => order,
        );
      }
    });
  }

  @override
  Future<Result<Order>> getOrderById(String orderId) {
    return guard<Order>(() async {
      // 1. Try local cache
      final Order? cached = _readOrderLocally(orderId);
      if (cached != null) return cached;

      // 2. Try backend
      try {
        final Map<String, dynamic> data = await _api.getOrderDetail(orderId);
        final Order mapped = _mapBackendOrder(data);
        await _saveOrderLocally(mapped);
        return mapped;
      } catch (_) {
        // Fallback
        return (await _fallbackRepo.getOrderById(orderId)).fold(
          (failure) => throw failure,
          (order) => order,
        );
      }
    });
  }

  @override
  Stream<Order> watchOrder(String orderId) {
    final StreamController<Order> controller = _orderStreams.putIfAbsent(
      orderId,
      () => StreamController<Order>.broadcast(),
    );

    // Initial emit from cache or fallback
    final Order? cached = _readOrderLocally(orderId);
    if (cached != null) {
      controller.add(cached);
    } else {
      _fallbackRepo.watchOrder(orderId).listen((Order o) {
        if (!controller.isClosed) controller.add(o);
      });
    }

    // Background polling for live status if on real backend
    _pollOrderStatus(orderId, controller);

    return controller.stream;
  }

  @override
  Future<Result<List<Order>>> getOrdersForUser(String userId) {
    return guard<List<Order>>(() async {
      try {
        final List<dynamic> backendOrders = await _api.getOrders();
        if (backendOrders.isNotEmpty) {
          final List<Order> mapped = backendOrders
              .map((dynamic o) => _mapBackendOrder(
                    o as Map<String, dynamic>,
                    fallbackUserId: userId,
                  ))
              .toList();
          return mapped;
        }
      } catch (_) {
        // Backend offline or empty
      }

      // Check local cache
      final List<Order> cached = _loadAllOrdersLocally();
      if (cached.isNotEmpty) {
        return cached.where((Order o) => o.userId == userId).toList();
      }

      return (await _fallbackRepo.getOrdersForUser(userId)).fold(
        (failure) => throw failure,
        (orders) => orders,
      );
    });
  }

  @override
  Future<Result<List<Order>>> getOrdersForRestaurant(String restaurantId) {
    return _fallbackRepo.getOrdersForRestaurant(restaurantId);
  }

  @override
  Stream<List<Order>> watchOrdersForRestaurant(String restaurantId) {
    return _fallbackRepo.watchOrdersForRestaurant(restaurantId);
  }

  @override
  Future<Result<List<Order>>> getOrdersForRider(String riderId) {
    return _fallbackRepo.getOrdersForRider(riderId);
  }

  @override
  Stream<List<Order>> watchOrdersForRider(String riderId) {
    return _fallbackRepo.watchOrdersForRider(riderId);
  }

  @override
  Future<Result<Order>> updateStatus({
    required String orderId,
    required OrderStatus status,
    String? note,
  }) {
    return guard<Order>(() async {
      try {
        final String backendStatus = switch (status) {
          OrderStatus.outForDelivery => 'IN_PROGRESS',
          OrderStatus.delivered => 'COMPLETED',
          OrderStatus.cancelled => 'CANCELLED',
          _ => 'IN_PROGRESS',
        };
        await _api.advanceOrderStatus(
          orderId,
          targetStatus: backendStatus,
          notes: note,
        );
      } catch (_) {
        // Fallback
      }

      final Order current = (await getOrderById(orderId)).fold(
        (failure) => throw failure,
        (order) => order,
      );
      final Order updated = Order(
        id: current.id,
        userId: current.userId,
        restaurantId: current.restaurantId,
        restaurantName: current.restaurantName,
        restaurantEmoji: current.restaurantEmoji,
        lines: current.lines,
        status: status,
        placedAt: current.placedAt,
        deliveryAddress: current.deliveryAddress,
        paymentMethod: current.paymentMethod,
        subtotal: current.subtotal,
        deliveryFee: current.deliveryFee,
        serviceFee: current.serviceFee,
        discount: current.discount,
        total: current.total,
        customerName: current.customerName,
        customerPhone: current.customerPhone,
        rider: current.rider,
        timeline: <OrderEvent>[
          ...current.timeline,
          OrderEvent(status: status, at: DateTime.now(), note: note),
        ],
        etaMinutes: current.etaMinutes,
        deliveredAt: status == OrderStatus.delivered ? DateTime.now() : null,
        riderNote: current.riderNote,
        isRated: current.isRated,
      );

      await _saveOrderLocally(updated);
      _notifyOrderUpdate(updated);
      return updated;
    });
  }

  @override
  Future<Result<Order>> cancelOrder(String orderId, {String? reason}) {
    return guard<Order>(() async {
      try {
        await _api.cancelOrder(
          orderId,
          reason: reason ?? 'Dibatalkan oleh pelanggan',
        );
      } catch (_) {
        // Fallback
      }
      return (await updateStatus(
        orderId: orderId,
        status: OrderStatus.cancelled,
        note: reason ?? 'Pesanan dibatalkan',
      )).fold(
        (failure) => throw failure,
        (order) => order,
      );
    });
  }

  @override
  Future<Result<Order>> markRated(String orderId) {
    return guard<Order>(() async {
      final Order current = (await getOrderById(orderId)).fold(
        (failure) => throw failure,
        (order) => order,
      );
      final Order updated = Order(
        id: current.id,
        userId: current.userId,
        restaurantId: current.restaurantId,
        restaurantName: current.restaurantName,
        restaurantEmoji: current.restaurantEmoji,
        lines: current.lines,
        status: current.status,
        placedAt: current.placedAt,
        deliveryAddress: current.deliveryAddress,
        paymentMethod: current.paymentMethod,
        subtotal: current.subtotal,
        deliveryFee: current.deliveryFee,
        serviceFee: current.serviceFee,
        discount: current.discount,
        total: current.total,
        customerName: current.customerName,
        customerPhone: current.customerPhone,
        rider: current.rider,
        timeline: current.timeline,
        etaMinutes: current.etaMinutes,
        deliveredAt: current.deliveredAt,
        riderNote: current.riderNote,
        isRated: true,
      );
      await _saveOrderLocally(updated);
      _notifyOrderUpdate(updated);
      return updated;
    });
  }

  // ---------------------------------------------------------------------------
  // Polling and Mapping
  // ---------------------------------------------------------------------------

  void _pollOrderStatus(String orderId, StreamController<Order> controller) {
    Timer.periodic(const Duration(seconds: 6), (Timer timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      try {
        final Map<String, dynamic> data = await _api.getOrderDetail(orderId);
        final Order updated = _mapBackendOrder(data);
        await _saveOrderLocally(updated);
        controller.add(updated);
        if (updated.status.isTerminal) {
          timer.cancel();
        }
      } catch (_) {
        // Silent ignore during background polling
      }
    });
  }

  void _notifyOrderUpdate(Order order) {
    final StreamController<Order>? sc = _orderStreams[order.id];
    if (sc != null && !sc.isClosed) {
      sc.add(order);
    }
  }

  Order _mapBackendOrder(Map<String, dynamic> json, {String? fallbackUserId}) {
    final String orderNum = json['order_number'] as String? ?? json['id'].toString();
    final String backendStatus = json['status'] as String? ?? 'SUBMITTED';

    final OrderStatus status = switch (backendStatus.toUpperCase()) {
      'SUBMITTED' || 'WAITING_BID' || 'WAITING_PRICE_APPROVAL' => OrderStatus.placed,
      'SEARCHING_PARTNER' => OrderStatus.confirmed,
      'PARTNER_ASSIGNED' => OrderStatus.preparing,
      'IN_PROGRESS' => OrderStatus.outForDelivery,
      'COMPLETED' => OrderStatus.delivered,
      'CANCELLED' => OrderStatus.cancelled,
      _ => OrderStatus.placed,
    };

    final double price = (json['final_price'] as num?)?.toDouble() ??
        (json['quoted_price'] as num?)?.toDouble() ??
        (json['estimated_price'] as num?)?.toDouble() ??
        25000.0;

    final String serviceName = json['service_name'] as String? ??
        (json['service_snapshot'] is Map ? (json['service_snapshot'] as Map)['service_name'] as String? : null) ??
        'Layanan SURUH';

    return Order(
      id: orderNum,
      userId: fallbackUserId ?? 'u-current',
      restaurantId: 'prov-suruh',
      restaurantName: serviceName,
      restaurantEmoji: '⚡',
      lines: const <CartItem>[],
      status: status,
      placedAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      deliveryAddress: const Address(
        id: 'addr-ptk-dest',
        label: AddressLabel.home,
        line1: 'Kota Pontianak',
        city: 'Pontianak',
        state: 'Kalimantan Barat',
        postcode: '78121',
      ),
      paymentMethod: PaymentMethod.cash,
      subtotal: price,
      deliveryFee: 0,
      serviceFee: 0,
      discount: 0,
      total: price,
      customerName: 'Pelanggan SURUH',
      customerPhone: '',
      rider: const DeliveryRider(
        id: 'driver-srh-1',
        name: 'Mitra SURUH Pontianak',
        vehicle: 'Motor Beat / Vario',
        plateNumber: 'KB 4567 XX',
        rating: 4.9,
        avatarEmoji: '🛵',
        phone: '+6281233334444',
      ),
      timeline: <OrderEvent>[
        OrderEvent(
          status: status,
          at: DateTime.now(),
          note: json['status_display'] as String?,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Local storage cache
  // ---------------------------------------------------------------------------

  Future<void> _saveOrderLocally(Order order) async {
    final List<Map<String, dynamic>> orders =
        _storage.readJsonList(LocalStorage.kOrders);
    final OrderModel model = OrderModel.fromEntity(order);
    final int idx =
        orders.indexWhere((Map<String, dynamic> o) => o['id'] == order.id);
    if (idx >= 0) {
      orders[idx] = model.toJson();
    } else {
      orders.insert(0, model.toJson());
    }
    await _storage.writeJsonList(LocalStorage.kOrders, orders);
  }

  Order? _readOrderLocally(String orderId) {
    final List<Map<String, dynamic>> orders =
        _storage.readJsonList(LocalStorage.kOrders);
    for (final Map<String, dynamic> o in orders) {
      if (o['id'] == orderId) {
        return OrderModel.fromJson(o);
      }
    }
    return null;
  }

  List<Order> _loadAllOrdersLocally() {
    final List<Map<String, dynamic>> raw =
        _storage.readJsonList(LocalStorage.kOrders);
    return raw
        .map((Map<String, dynamic> o) => OrderModel.fromJson(o))
        .toList();
  }
}
