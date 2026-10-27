import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../error/exceptions.dart';

/// Thin, testable wrapper over [SharedPreferences].
///
/// Everything the app caches for offline use (restaurant catalogue, cart,
/// session, order history) goes through here, so there is exactly one place
/// that knows about storage keys and JSON encoding.
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorage> create() async =>
      LocalStorage(await SharedPreferences.getInstance());

  // --- Keys -----------------------------------------------------------------
  static const String kOnboardingSeen = 'onboarding_seen';
  static const String kSession = 'session_user';
  static const String kThemeMode = 'theme_mode';
  static const String kCart = 'cart_state';
  static const String kRestaurants = 'cache_restaurants';
  static const String kFoods = 'cache_foods';
  static const String kOrders = 'cache_orders';
  static const String kReviews = 'cache_reviews';
  static const String kFavourites = 'user_favourites';
  static const String kAddresses = 'user_addresses';
  static const String kRecentSearches = 'recent_searches';
  static const String kCacheStamp = 'cache_written_at';

  // --- Primitives -----------------------------------------------------------
  bool getBool(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;

  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  List<String> getStringList(String key) => _prefs.getStringList(key) ?? const <String>[];

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  bool contains(String key) => _prefs.containsKey(key);

  // --- JSON helpers ---------------------------------------------------------
  Map<String, dynamic>? readJson(String key) {
    final String? raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException catch (error) {
      throw CacheException('Corrupt cache entry for "$key"', error);
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  List<Map<String, dynamic>> readJsonList(String key) {
    final String? raw = _prefs.getString(key);
    if (raw == null) return const <Map<String, dynamic>>[];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
    } on FormatException catch (error) {
      throw CacheException('Corrupt cache list for "$key"', error);
    }
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));

  /// Marks when the catalogue cache was last refreshed, used to decide whether
  /// a background refresh is worth doing.
  Future<void> stampCache() =>
      _prefs.setString(kCacheStamp, DateTime.now().toIso8601String());

  DateTime? get cacheWrittenAt {
    final String? raw = _prefs.getString(kCacheStamp);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Clears user-scoped data on sign-out. Cached catalogue survives so the app
  /// still renders offline on the next launch.
  Future<void> clearSession() async {
    await Future.wait<void>(<Future<void>>[
      _prefs.remove(kSession),
      _prefs.remove(kCart),
      _prefs.remove(kFavourites),
      _prefs.remove(kAddresses),
    ]);
  }
}
