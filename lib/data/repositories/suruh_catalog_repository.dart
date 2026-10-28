import 'dart:async';

import '../../core/error/exceptions.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/network/suruh_api_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/entities/restaurant.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Catalog repository implementation that pulls dynamic categories and on-demand
/// services from the SURUH Django backend (`https://suruhjak.teknusa.com/`),
/// with SQLite local database caching for cost savings, instant load, and offline use.
class SuruhCatalogRepository implements CatalogRepository {
  SuruhCatalogRepository({
    required SuruhApiClient api,
    required LocalStorage storage,
    required ConnectivityService connectivity,
    AppDatabase? database,
  })  : _api = api,
        _storage = storage,
        _connectivity = connectivity,
        _database = database ?? AppDatabase.instance;

  final SuruhApiClient _api;
  final LocalStorage _storage;
  final ConnectivityService _connectivity;
  final AppDatabase _database;

  List<FoodCategory>? _categoriesCache;
  List<Restaurant>? _restaurantsCache;
  List<FoodItem>? _servicesCache;

  @override
  Future<Result<List<FoodCategory>>> getCategories() {
    return guard<List<FoodCategory>>(() async {
      if (_categoriesCache != null && _categoriesCache!.isNotEmpty) {
        return _categoriesCache!;
      }

      // 1. Cek cache SQLite terlebih dahulu untuk performa instan & hemat bandwidth API
      final List<Map<String, dynamic>> sqliteCached = await _database.getCachedCategories();
      if (sqliteCached.isNotEmpty) {
        _categoriesCache = sqliteCached.map((Map<String, dynamic> c) {
          final String name = c['name'] as String? ?? 'Layanan';
          final String slug = c['slug'] as String? ?? c['id'].toString();
          final int count = c['active_services_count'] as int? ?? c['item_count'] as int? ?? 1;
          return FoodCategory(
            id: slug,
            name: name,
            emoji: _categoryEmoji(name, slug),
            itemCount: count,
          );
        }).toList();
      }

      // 2. Refresh dari backend live bila memungkinkan
      try {
        final List<dynamic> raw = await _api.getCategories();
        if (raw.isNotEmpty) {
          final List<Map<String, dynamic>> maps = raw.cast<Map<String, dynamic>>();
          await _database.cacheCategories(maps); // Simpan ke SQLite

          final List<FoodCategory> mapped = maps.map((Map<String, dynamic> c) {
            final String name = c['name'] as String? ?? 'Layanan';
            final String slug = c['slug'] as String? ?? c['id'].toString();
            final int count = c['active_services_count'] as int? ?? c['item_count'] as int? ?? 1;
            return FoodCategory(
              id: slug,
              name: name,
              emoji: _categoryEmoji(name, slug),
              itemCount: count,
            );
          }).toList();
          _categoriesCache = mapped;
          return mapped;
        }
      } catch (_) {
        // Backend offline atau error, jika sudah ada cache SQLite kembalikan cache
        if (_categoriesCache != null && _categoriesCache!.isNotEmpty) {
          return _categoriesCache!;
        }
      }

      return _categoriesCache ?? const <FoodCategory>[];
    });
  }

  @override
  Future<Result<List<Restaurant>>> getRestaurants([RestaurantFilter filter = const RestaurantFilter()]) {
    return guard<List<Restaurant>>(() async {
      final List<Restaurant> all = await _loadOrFetchRestaurants();
      return _applyFilters(all, filter);
    });
  }

  @override
  Future<Result<Restaurant>> getRestaurantById(String id) {
    return guard<Restaurant>(() async {
      final List<Restaurant> all = await _loadOrFetchRestaurants();
      final Restaurant? match = all.cast<Restaurant?>().firstWhere(
            (Restaurant? r) => r?.id == id,
            orElse: () => null,
          );
      if (match != null) return match;
      throw NotFoundException('Layanan SURUH dengan ID "$id" tidak ditemukan.');
    });
  }

  @override
  Future<Result<List<Restaurant>>> getFeaturedRestaurants() {
    return guard<List<Restaurant>>(() async {
      final List<Restaurant> all = await _loadOrFetchRestaurants();
      return all.where((Restaurant r) => r.isPromoted).toList();
    });
  }

  @override
  Future<Result<List<FoodItem>>> getMenuForRestaurant(String restaurantId) {
    return guard<List<FoodItem>>(() async {
      final List<FoodItem> items = await _loadOrFetchServices();
      return items.where((FoodItem i) => i.restaurantId == restaurantId).toList();
    });
  }

  @override
  Future<Result<FoodItem>> getFoodItemById(String id) {
    return guard<FoodItem>(() async {
      final List<FoodItem> items = await _loadOrFetchServices();
      final FoodItem? match = items.cast<FoodItem?>().firstWhere(
            (FoodItem? i) => i?.id == id,
            orElse: () => null,
          );
      if (match != null) return match;
      throw NotFoundException('Item layanan "$id" tidak ditemukan.');
    });
  }

  @override
  Future<Result<List<FoodItem>>> getPopularDishes({int limit = 10}) {
    return guard<List<FoodItem>>(() async {
      final List<FoodItem> items = await _loadOrFetchServices();
      final List<FoodItem> popular = items.where((FoodItem i) => i.isPopular).toList();
      return (popular.isNotEmpty ? popular : items).take(limit).toList();
    });
  }

  @override
  Future<Result<List<FoodItem>>> getDiscountedDishes({int limit = 10}) {
    return guard<List<FoodItem>>(() async {
      final List<FoodItem> items = await _loadOrFetchServices();
      return items.where((FoodItem i) => i.isOnOffer).take(limit).toList();
    });
  }

  @override
  Future<Result<List<Promo>>> getPromos() {
    return guard<List<Promo>>(() async {
      return const <Promo>[
        Promo(
          id: 'promo-ptk-1',
          code: 'SURUHHEMAT',
          title: 'Diskon Jasa Titip Pontianak',
          subtitle: 'Hemat ongkir hingga Rp 10.000 untuk pengiriman dalam kota Pontianak',
          discountPercent: 20,
          maxDiscountMyr: 10000,
          minSpendMyr: 25000,
          emoji: '🛒',
          badge: 'HEMAT',
        ),
        Promo(
          id: 'promo-ptk-2',
          code: 'ANTARDOKUMEN',
          title: 'Layanan Kilat Dokumen',
          subtitle: 'Pasti sampai & aman langsung ke penerima di Pontianak & Kubu Raya',
          discountPercent: 15,
          maxDiscountMyr: 8000,
          minSpendMyr: 20000,
          emoji: '📄',
          badge: 'KILAT',
        ),
      ];
    });
  }

  @override
  Future<Result<SearchResults>> search(String query) {
    return guard<SearchResults>(() async {
      final String term = query.trim().toLowerCase();
      if (term.isEmpty) {
        return SearchResults(restaurants: const <Restaurant>[], dishes: const <FoodItem>[], query: query);
      }

      final List<Restaurant> allR = await _loadOrFetchRestaurants();
      final List<FoodItem> allS = await _loadOrFetchServices();

      final List<Restaurant> matchedR = allR.where((Restaurant r) {
        return r.name.toLowerCase().contains(term) ||
            r.cuisines.any((String c) => c.toLowerCase().contains(term)) ||
            r.description.toLowerCase().contains(term);
      }).toList();

      final List<FoodItem> matchedS = allS.where((FoodItem i) {
        return i.name.toLowerCase().contains(term) ||
            i.description.toLowerCase().contains(term) ||
            i.restaurantName.toLowerCase().contains(term);
      }).toList();

      return SearchResults(
        restaurants: matchedR,
        dishes: matchedS,
        query: query,
      );
    });
  }

  @override
  Future<Result<void>> refresh() {
    return guard<void>(() async {
      _categoriesCache = null;
      _restaurantsCache = null;
      _servicesCache = null;
      await _storage.stampCache();
      await getCategories();
      await _loadOrFetchRestaurants();
    });
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  Future<List<Restaurant>> _loadOrFetchRestaurants() async {
    if (_restaurantsCache != null && _restaurantsCache!.isNotEmpty) {
      return _restaurantsCache!;
    }

    if (!(await _connectivity.isOnline)) {
      final List<Map<String, dynamic>> sqliteCached = await _database.getCachedServices();
      if (sqliteCached.isNotEmpty) {
        final List<Restaurant> providers = _buildProvidersFromServices(sqliteCached);
        _restaurantsCache = providers;
        return providers;
      }
    }

    try {
      final List<dynamic> servicesJson = await _api.getServices();
      if (servicesJson.isNotEmpty) {
        final List<Map<String, dynamic>> maps = servicesJson.cast<Map<String, dynamic>>();
        await _database.cacheServices(maps);
        final List<Restaurant> providers = _buildProvidersFromServices(servicesJson);
        _restaurantsCache = providers;
        return providers;
      }
    } catch (_) {
      // Backend offline or error: check SQLite cache
      final List<Map<String, dynamic>> sqliteCached = await _database.getCachedServices();
      if (sqliteCached.isNotEmpty) {
        final List<Restaurant> providers = _buildProvidersFromServices(sqliteCached);
        _restaurantsCache = providers;
        return providers;
      }
    }

    return _restaurantsCache ?? const <Restaurant>[];
  }

  Future<List<FoodItem>> _loadOrFetchServices() async {
    if (_servicesCache != null && _servicesCache!.isNotEmpty) {
      return _servicesCache!;
    }

    // 1. Cek cache SQLite terlebih dahulu untuk performa instan & hemat bandwidth
    final List<Map<String, dynamic>> sqliteCached = await _database.getCachedServices();
    if (sqliteCached.isNotEmpty) {
      _servicesCache = _mapServicesList(sqliteCached);
    }

    // 2. Fetch live data dari server https://suruhjak.teknusa.com/
    try {
      final List<dynamic> raw = await _api.getServices();
      if (raw.isNotEmpty) {
        final List<Map<String, dynamic>> maps = raw.cast<Map<String, dynamic>>();
        await _database.cacheServices(maps); // Simpan ke SQLite lokal

        final List<FoodItem> items = _mapServicesList(maps);
        _servicesCache = items;
        return items;
      }
    } catch (_) {
      // Backend offline atau error, jika sudah ada cache SQLite kembalikan cache
      if (_servicesCache != null && _servicesCache!.isNotEmpty) {
        return _servicesCache!;
      }
    }

    return _servicesCache ?? const <FoodItem>[];
  }

  List<FoodItem> _mapServicesList(List<Map<String, dynamic>> rawList) {
    return rawList.map((Map<String, dynamic> s) {
      final String id = s['id']?.toString() ?? s['slug']?.toString() ?? 'svc';
      final String name = s['name'] as String? ?? 'Layanan SURUH';
      final String catName = s['category_name'] as String? ?? 'Umum';
      final String catSlug = s['category_slug'] as String? ?? 'umum';
      final String desc = s['short_description'] as String? ?? s['description'] as String? ?? '';

      double price = 15000.0;
      if (s['pricing_configuration'] is Map) {
        final Map<String, dynamic> p = s['pricing_configuration'] as Map<String, dynamic>;
        price = (p['base_price'] as num?)?.toDouble() ?? 15000.0;
      }

      return FoodItem(
        id: id,
        restaurantId: 'prov-$catSlug',
        restaurantName: 'SURUH $catName Pontianak',
        name: name,
        description: desc,
        priceMyr: price,
        categoryId: catSlug,
        emoji: _categoryEmoji(name, catSlug),
        rating: 4.9,
        reviewCount: 38,
        isPopular: true,
        isAvailable: true,
      );
    }).toList();
  }

  List<Restaurant> _buildProvidersFromServices(List<dynamic> services) {
    // Group services by category to create service hubs/providers
    final Map<String, List<Map<String, dynamic>>> byCategory = <String, List<Map<String, dynamic>>>{};
    for (final dynamic item in services) {
      final Map<String, dynamic> s = item as Map<String, dynamic>;
      final String cat = s['category_name'] as String? ?? 'Umum';
      byCategory.putIfAbsent(cat, () => <Map<String, dynamic>>[]).add(s);
    }

    return byCategory.entries.map((MapEntry<String, List<Map<String, dynamic>>> entry) {
      final String catName = entry.key;
      final String catSlug = entry.value.first['category_slug'] as String? ?? 'umum';
      return Restaurant(
        id: 'prov-$catSlug',
        name: 'SURUH $catName Pontianak',
        cuisines: <String>[catName, 'On-Demand', 'Pontianak'],
        emoji: _categoryEmoji(catName, catSlug),
        rating: 4.9,
        reviewCount: 88,
        deliveryFeeMyr: 5000.0,
        minOrderMyr: 10000.0,
        etaMinMinutes: 15,
        etaMaxMinutes: 30,
        distanceKm: 2.1,
        isOpen: true,
        isPromoted: true,
        promoText: 'Tarif transparan & kurir terpercaya',
        description: 'Layanan resmi platform SURUH di area Kota Pontianak & sekitarnya.',
        address: const Address(
          id: 'addr-hub-ptk',
          label: AddressLabel.work,
          line1: 'Jl. Gajah Mada No. 12',
          city: 'Pontianak',
          state: 'Kalimantan Barat',
          postcode: '78121',
        ),
      );
    }).toList();
  }

  String _categoryEmoji(String name, String slug) {
    final String lower = '${name.toLowerCase()} ${slug.toLowerCase()}';
    if (lower.contains('belanja') || lower.contains('titip')) return '🛒';
    if (lower.contains('dokumen') || lower.contains('surat')) return '📄';
    if (lower.contains('bersih') || lower.contains('rumah')) return '🧹';
    if (lower.contains('antre') || lower.contains('bantu')) return '⏳';
    if (lower.contains('angkut') || lower.contains('pindah') || lower.contains('mobil')) return '🚚';
    if (lower.contains('makan')) return '🍲';
    return '⚡';
  }

  List<Restaurant> _applyFilters(List<Restaurant> list, RestaurantFilter filter) {
    return list.where((Restaurant r) {
      if (filter.categoryId != null && !r.cuisines.any((String c) => c.toLowerCase().contains(filter.categoryId!.toLowerCase()))) {
        return false;
      }
      if (filter.freeDeliveryOnly && !r.hasFreeDelivery) return false;
      if (filter.openNowOnly && !r.isOpen) return false;
      if (filter.minRating != null && r.rating < filter.minRating!) return false;
      if (filter.query != null && filter.query!.isNotEmpty) {
        final String q = filter.query!.toLowerCase();
        final bool hit = r.name.toLowerCase().contains(q) ||
            r.cuisines.any((String c) => c.toLowerCase().contains(q));
        if (!hit) return false;
      }
      return true;
    }).toList();
  }
}
