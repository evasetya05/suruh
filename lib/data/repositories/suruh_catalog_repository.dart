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
import '../datasources/local/demo_data_source.dart';

/// Catalog repository implementation that pulls dynamic categories and on-demand
/// services from the SURUH Django backend (`https://suruhjak.teknusa.com/`),
/// with SQLite local database caching for cost savings, instant load, and offline use.
class SuruhCatalogRepository implements CatalogRepository {
  SuruhCatalogRepository({
    required SuruhApiClient api,
    required LocalStorage storage,
    required ConnectivityService connectivity,
    required DemoDataSource fallbackSource,
    AppDatabase? database,
  })  : _api = api,
        _storage = storage,
        _connectivity = connectivity,
        _fallback = fallbackSource,
        _database = database ?? AppDatabase.instance;

  final SuruhApiClient _api;
  final LocalStorage _storage;
  final ConnectivityService _connectivity;
  final DemoDataSource _fallback;
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

      // Default curated categories for SURUH Pontianak
      return _defaultPontianakCategories();
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

    try {
      final List<dynamic> servicesJson = await _api.getServices();
      if (servicesJson.isNotEmpty) {
        final List<Restaurant> providers = _buildProvidersFromServices(servicesJson);
        _restaurantsCache = providers;
        return providers;
      }
    } catch (_) {
      if (!(await _connectivity.isOnline)) {
        final List<Restaurant> fallbackList = await _fallback.getRestaurants();
        if (fallbackList.isNotEmpty) {
          _restaurantsCache = fallbackList;
          return fallbackList;
        }
      }
    }

    final List<Restaurant> defaults = _defaultPontianakProviders();
    _restaurantsCache = defaults;
    return defaults;
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

      if (!(await _connectivity.isOnline)) {
        final List<FoodItem> fallbackItems = await _fallback.getFoods();
        if (fallbackItems.isNotEmpty) {
          _servicesCache = fallbackItems;
          return fallbackItems;
        }
      }
    }

    final List<FoodItem> defaults = _defaultPontianakServices();
    _servicesCache = defaults;
    return defaults;
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

  List<FoodCategory> _defaultPontianakCategories() => const <FoodCategory>[
        FoodCategory(id: 'titip-belanja', name: 'Titip & Belanja', emoji: '🛒', itemCount: 4),
        FoodCategory(id: 'antar-dokumen', name: 'Antar Dokumen', emoji: '📄', itemCount: 3),
        FoodCategory(id: 'bersih-rumah', name: 'Bersih Rumah', emoji: '🧹', itemCount: 2),
        FoodCategory(id: 'bantu-antre', name: 'Bantu Antre & Urusan', emoji: '⏳', itemCount: 3),
        FoodCategory(id: 'angkut-barang', name: 'Angkut Barang', emoji: '🚚', itemCount: 2),
      ];

  List<Restaurant> _defaultPontianakProviders() => const <Restaurant>[
        Restaurant(
          id: 'prov-titip-belanja',
          name: 'SURUH Titip & Belanja Pontianak',
          cuisines: <String>['Belanja Pasar', 'Titip Makanan', 'Kurir Khusus'],
          emoji: '🛒',
          rating: 4.9,
          reviewCount: 142,
          deliveryFeeMyr: 8000.0,
          minOrderMyr: 15000.0,
          etaMinMinutes: 20,
          etaMaxMinutes: 40,
          distanceKm: 1.8,
          isOpen: true,
          isPromoted: true,
          promoText: 'Belanja di mana saja, kurir SURUH siap antar',
          description: 'Mitra kurir profesional siap membelikan kebutuhan pasar, obat apotek, maupun makanan lokal Pontianak.',
          address: Address(
            id: 'addr-ptk-1',
            label: AddressLabel.work,
            line1: 'Jl. Tanjungpura No. 45',
            city: 'Pontianak',
            state: 'Kalimantan Barat',
            postcode: '78111',
          ),
        ),
        Restaurant(
          id: 'prov-antar-dokumen',
          name: 'SURUH Antar Dokumen & Surat',
          cuisines: <String>['Dokumen Resmi', 'Ijazah/Sertifikat', 'Sameday'],
          emoji: '📄',
          rating: 5.0,
          reviewCount: 96,
          deliveryFeeMyr: 12000.0,
          minOrderMyr: 12000.0,
          etaMinMinutes: 15,
          etaMaxMinutes: 30,
          distanceKm: 2.4,
          isOpen: true,
          isPromoted: true,
          promoText: 'Pengantaran aman bergaransi dokumen penting',
          description: 'Layanan kurir khusus dokumen rahasia, legalisir, ijazah, atau invoice dengan bukti serah terima foto.',
          address: Address(
            id: 'addr-ptk-2',
            label: AddressLabel.work,
            line1: 'Jl. Ahmad Yani No. 8',
            city: 'Pontianak',
            state: 'Kalimantan Barat',
            postcode: '78124',
          ),
        ),
        Restaurant(
          id: 'prov-bantu-antre',
          name: 'SURUH Asisten & Urusan Pribadi',
          cuisines: <String>['Antre Rumah Sakit', 'Urus Berkas', 'Bantuan Khusus'],
          emoji: '⏳',
          rating: 4.8,
          reviewCount: 78,
          deliveryFeeMyr: 25000.0,
          minOrderMyr: 25000.0,
          etaMinMinutes: 30,
          etaMaxMinutes: 60,
          distanceKm: 3.1,
          isOpen: true,
          isPromoted: false,
          promoText: 'Ada urusan repot? Suruh kami yang selesaikan',
          description: 'Jasa bantuan mengantre nomor antrean dokter, urus berkas instansi, hingga penitipan kunci.',
          address: Address(
            id: 'addr-ptk-3',
            label: AddressLabel.work,
            line1: 'Jl. Komyos Soedarso No. 19',
            city: 'Pontianak',
            state: 'Kalimantan Barat',
            postcode: '78113',
          ),
        ),
      ];

  List<FoodItem> _defaultPontianakServices() => const <FoodItem>[
        FoodItem(
          id: 'svc-titip-beli',
          restaurantId: 'prov-titip-belanja',
          restaurantName: 'SURUH Titip & Belanja Pontianak',
          name: 'Jasa Titip Beli Kebutuhan / Makanan',
          description: 'Mitra membelikan pesanan makanan khas Pontianak, kebutuhan pasar Flamboyan, atau minimarket.',
          priceMyr: 15000.0,
          categoryId: 'titip-belanja',
          emoji: '🛍️',
          rating: 4.9,
          reviewCount: 110,
          isPopular: true,
        ),
        FoodItem(
          id: 'svc-antar-dokumen',
          restaurantId: 'prov-antar-dokumen',
          restaurantName: 'SURUH Antar Dokumen & Surat',
          name: 'Suruh Antar Dokumen Penting',
          description: 'Antar berkas kantor, surat nikah, ijazah, dan dokumen legal aman dalam map tahan air.',
          priceMyr: 15000.0,
          categoryId: 'antar-dokumen',
          emoji: '📁',
          rating: 5.0,
          reviewCount: 85,
          isPopular: true,
        ),
        FoodItem(
          id: 'svc-antre-rs',
          restaurantId: 'prov-bantu-antre',
          restaurantName: 'SURUH Asisten & Urusan Pribadi',
          name: 'Bantu Ambil Nomor Antrean RS / Bank',
          description: 'Mitra datang pagi untuk mengambil nomor antrean poli di RSUD Soedarso, Antonius, atau bank.',
          priceMyr: 30000.0,
          categoryId: 'bantu-antre',
          emoji: '🏥',
          rating: 4.8,
          reviewCount: 64,
          isPopular: true,
        ),
      ];

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
