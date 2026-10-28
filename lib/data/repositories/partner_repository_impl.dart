import '../../core/network/suruh_api_client.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/partner_repository.dart';
import '../models/order_model.dart';

class PartnerRepositoryImpl implements PartnerRepository {
  PartnerRepositoryImpl({
    required SuruhApiClient api,
    required LocalStorage storage,
  })  : _api = api,
        _storage = storage;

  final SuruhApiClient _api;
  final LocalStorage _storage;

  @override
  Future<Result<Restaurant>> getManagedRestaurant(String ownerId) {
    return guard<Restaurant>(() async {
      return const Restaurant(
        id: 'prov-partner',
        name: 'SURUH Hub Mitra Pontianak',
        cuisines: <String>['On-Demand', 'Mitra Resmi', 'Pontianak'],
        emoji: '⚡',
        rating: 5.0,
        reviewCount: 24,
        deliveryFeeMyr: 5000,
        minOrderMyr: 10000,
        etaMinMinutes: 15,
        etaMaxMinutes: 30,
        distanceKm: 1.5,
        isOpen: true,
        isPromoted: true,
        promoText: 'Mitra Layanan Pontianak Terverifikasi',
        description: 'Layanan operasional mitra resmi platform SURUH Kota Pontianak.',
        address: Address(
          id: 'addr-mitra',
          label: AddressLabel.work,
          line1: 'Jl. Gajah Mada No. 12',
          city: 'Pontianak',
          state: 'Kalimantan Barat',
          postcode: '78121',
        ),
      );
    });
  }

  @override
  Future<Result<PartnerStats>> getStats(String restaurantId) {
    return guard<PartnerStats>(() async {
      final List<Map<String, dynamic>> rawOrders =
          _storage.readJsonList(LocalStorage.kOrders);
      final List<OrderModel> orders =
          rawOrders.map((Map<String, dynamic> o) => OrderModel.fromJson(o)).toList();

      final DateTime now = DateTime.now();
      final DateTime startOfToday = DateTime(now.year, now.month, now.day);

      final List<OrderModel> today = orders
          .where(
            (OrderModel o) =>
                o.placedAt.isAfter(startOfToday) &&
                o.status != OrderStatus.cancelled,
          )
          .toList();

      final double todayRevenue =
          today.fold<double>(0, (double s, OrderModel o) => s + o.subtotal);

      final List<double> revenueByDay = <double>[
        for (int daysAgo = 6; daysAgo >= 0; daysAgo--)
          _revenueOn(orders, startOfToday.subtract(Duration(days: daysAgo))),
      ];

      return PartnerStats(
        todayRevenue: todayRevenue,
        todayOrders: today.length,
        pendingOrders:
            orders.where((OrderModel o) => o.status == OrderStatus.placed).length,
        activeMenuItems: 5,
        averageRating: 4.9,
        totalReviews: 24,
        revenueByDay: revenueByDay,
      );
    });
  }

  double _revenueOn(List<OrderModel> orders, DateTime day) {
    final DateTime end = day.add(const Duration(days: 1));
    return orders
        .where(
          (OrderModel o) =>
              o.status != OrderStatus.cancelled &&
              o.placedAt.isAfter(day) &&
              o.placedAt.isBefore(end),
        )
        .fold<double>(0, (double s, OrderModel o) => s + o.subtotal);
  }

  @override
  Future<Result<List<FoodItem>>> getMenu(String restaurantId) {
    return guard<List<FoodItem>>(() async {
      try {
        final List<dynamic> raw = await _api.getServices();
        return raw.map((dynamic s) {
          final Map<String, dynamic> item = s as Map<String, dynamic>;
          final String name = item['name'] as String? ?? 'Layanan SURUH';
          final String cat = item['category_name'] as String? ?? 'Umum';
          final String slug = item['slug'] as String? ?? 'svc';
          double price = 15000;
          if (item['pricing_configuration'] is Map) {
            price = ((item['pricing_configuration'] as Map)['base_price'] as num?)?.toDouble() ?? 15000;
          }
          return FoodItem(
            id: slug,
            restaurantId: restaurantId,
            restaurantName: 'SURUH $cat Pontianak',
            name: name,
            description: item['short_description'] as String? ?? '',
            priceMyr: price,
            categoryId: cat,
            emoji: '⚡',
            rating: 5.0,
            reviewCount: 10,
          );
        }).toList();
      } catch (_) {
        return const <FoodItem>[];
      }
    });
  }

  @override
  Future<Result<FoodItem>> createMenuItem({
    required String restaurantId,
    required String name,
    required String description,
    required double priceMyr,
    required String categoryId,
    required String emoji,
    double? discountPriceMyr,
    List<String> ingredients = const <String>[],
    bool isVegetarian = false,
    bool isSpicy = false,
    int prepMinutes = 15,
  }) {
    return guard<FoodItem>(() async {
      return FoodItem(
        id: 'svc-${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        restaurantName: 'SURUH Pontianak',
        name: name,
        description: description,
        priceMyr: priceMyr,
        categoryId: categoryId,
        emoji: emoji,
        rating: 5.0,
        reviewCount: 0,
      );
    });
  }

  @override
  Future<Result<FoodItem>> updateMenuItem(FoodItem item) =>
      guard<FoodItem>(() async => item);

  @override
  Future<Result<void>> deleteMenuItem(String foodItemId) =>
      guard<void>(() async {});

  @override
  Future<Result<FoodItem>> setItemAvailability({
    required String foodItemId,
    required bool isAvailable,
  }) {
    return guard<FoodItem>(() async {
      return FoodItem(
        id: foodItemId,
        restaurantId: 'prov-partner',
        restaurantName: 'SURUH Pontianak',
        name: 'Layanan SURUH',
        description: '',
        priceMyr: 15000,
        categoryId: 'umum',
        emoji: '⚡',
        rating: 5.0,
        reviewCount: 1,
        isAvailable: isAvailable,
      );
    });
  }

  @override
  Future<Result<Restaurant>> setRestaurantOpen({
    required String restaurantId,
    required bool isOpen,
  }) {
    return guard<Restaurant>(() async {
      final Result<Restaurant> res = await getManagedRestaurant('owner');
      return res.fold((failure) => throw failure, (r) => r.copyWith(isOpen: isOpen));
    });
  }
}
