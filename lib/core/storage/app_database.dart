import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;

/// Local SQLite Database for SURUH Flutter App.
///
/// Digunakan untuk:
/// 1. Menghemat biaya server / VPS bandwidth dengan caching layanan & kategori lokal.
/// 2. Mode offline: pengguna tetap bisa melihat katalog & riwayat pesanan tanpa koneksi internet.
/// 3. Performa instan (0ms) saat membuka aplikasi.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  sqflite.Database? _db;

  /// In-memory fallback untuk web / headless test environment
  final Map<String, String> _memoryStore = <String, String>{};

  /// Inisialisasi koneksi SQLite
  Future<void> init() async {
    if (kIsWeb) return;

    try {
      final String dbDir = await sqflite.getDatabasesPath();
      final String dbPath = p.join(dbDir, 'suruh_local.db');

      _db = await sqflite.openDatabase(
        dbPath,
        version: 1,
        onCreate: (sqflite.Database db, int version) async {
          final sqflite.Batch batch = db.batch();

          // 1. Tabel Cache Kategori Layanan
          batch.execute('''
            CREATE TABLE IF NOT EXISTS categories_cache (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              emoji TEXT,
              item_count INTEGER DEFAULT 0,
              json_data TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          // 2. Tabel Cache Layanan / Services
          batch.execute('''
            CREATE TABLE IF NOT EXISTS services_cache (
              id TEXT PRIMARY KEY,
              category_slug TEXT,
              name TEXT NOT NULL,
              price REAL,
              json_data TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          // 3. Tabel Cache Riwayat Pesanan (Orders)
          batch.execute('''
            CREATE TABLE IF NOT EXISTS orders_cache (
              id TEXT PRIMARY KEY,
              status TEXT NOT NULL,
              total REAL NOT NULL,
              json_data TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');

          // 4. Tabel Key-Value Umum untuk SQLite
          batch.execute('''
            CREATE TABLE IF NOT EXISTS key_value_store (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');

          await batch.commit(noResult: true);
        },
      );
    } catch (e) {
      debugPrint('[AppDatabase] SQLite initialization fallback to memory: $e');
    }
  }

  bool get isReady => _db != null;

  // --- KATEGORI -------------------------------------------------------------

  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    if (_db == null) {
      _memoryStore['categories'] = jsonEncode(categories);
      return;
    }

    try {
      final sqflite.Batch batch = _db!.batch();
      final int now = DateTime.now().millisecondsSinceEpoch;

      for (final Map<String, dynamic> c in categories) {
        final String id = c['id']?.toString() ?? c['slug']?.toString() ?? '';
        if (id.isEmpty) continue;

        batch.insert(
          'categories_cache',
          <String, Object?>{
            'id': id,
            'name': c['name'] ?? '',
            'emoji': c['emoji'] ?? '',
            'item_count': c['item_count'] ?? c['active_services_count'] ?? 0,
            'json_data': jsonEncode(c),
            'updated_at': now,
          },
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[AppDatabase] Error caching categories: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedCategories() async {
    if (_db == null) {
      final String? raw = _memoryStore['categories'];
      if (raw == null) return <Map<String, dynamic>>[];
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    }

    try {
      final List<Map<String, Object?>> rows = await _db!.query(
        'categories_cache',
        orderBy: 'item_count DESC',
      );

      return rows.map((Map<String, Object?> row) {
        final String rawJson = row['json_data'] as String;
        return jsonDecode(rawJson) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('[AppDatabase] Error reading cached categories: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // --- LAYANAN / SERVICES ---------------------------------------------------

  Future<void> cacheServices(List<Map<String, dynamic>> services) async {
    if (_db == null) {
      _memoryStore['services'] = jsonEncode(services);
      return;
    }

    try {
      final sqflite.Batch batch = _db!.batch();
      final int now = DateTime.now().millisecondsSinceEpoch;

      for (final Map<String, dynamic> s in services) {
        final String id = s['id']?.toString() ?? '';
        if (id.isEmpty) continue;

        batch.insert(
          'services_cache',
          <String, Object?>{
            'id': id,
            'category_slug': s['category_slug'] ?? '',
            'name': s['name'] ?? '',
            'price': (s['price'] is num) ? (s['price'] as num).toDouble() : 0.0,
            'json_data': jsonEncode(s),
            'updated_at': now,
          },
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[AppDatabase] Error caching services: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedServices({String? categorySlug}) async {
    if (_db == null) {
      final String? raw = _memoryStore['services'];
      if (raw == null) return <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> all =
          (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      if (categorySlug == null || categorySlug.isEmpty) return all;
      return all.where((Map<String, dynamic> item) => item['category_slug'] == categorySlug).toList();
    }

    try {
      final List<Map<String, Object?>> rows;
      if (categorySlug != null && categorySlug.isNotEmpty) {
        rows = await _db!.query(
          'services_cache',
          where: 'category_slug = ?',
          whereArgs: <Object>[categorySlug],
          orderBy: 'name ASC',
        );
      } else {
        rows = await _db!.query('services_cache', orderBy: 'name ASC');
      }

      return rows.map((Map<String, Object?> row) {
        final String rawJson = row['json_data'] as String;
        return jsonDecode(rawJson) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('[AppDatabase] Error reading cached services: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // --- RIWAYAT PESANAN / ORDERS --------------------------------------------

  Future<void> cacheOrder(Map<String, dynamic> order) async {
    final String id = order['id']?.toString() ?? '';
    if (id.isEmpty) return;

    if (_db == null) {
      final List<Map<String, dynamic>> list = await getCachedOrders();
      list.removeWhere((Map<String, dynamic> o) => o['id']?.toString() == id);
      list.insert(0, order);
      _memoryStore['orders'] = jsonEncode(list);
      return;
    }

    try {
      await _db!.insert(
        'orders_cache',
        <String, Object?>{
          'id': id,
          'status': order['status']?.toString() ?? 'pending',
          'total': (order['total'] is num) ? (order['total'] as num).toDouble() : 0.0,
          'json_data': jsonEncode(order),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[AppDatabase] Error caching order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedOrders() async {
    if (_db == null) {
      final String? raw = _memoryStore['orders'];
      if (raw == null) return <Map<String, dynamic>>[];
      return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    }

    try {
      final List<Map<String, Object?>> rows = await _db!.query(
        'orders_cache',
        orderBy: 'created_at DESC',
      );

      return rows.map((Map<String, Object?> row) {
        final String rawJson = row['json_data'] as String;
        return jsonDecode(rawJson) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('[AppDatabase] Error reading cached orders: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // --- KEY VALUE STORE (SQLITE) --------------------------------------------

  Future<void> setString(String key, String value) async {
    if (_db == null) {
      _memoryStore[key] = value;
      return;
    }

    try {
      await _db!.insert(
        'key_value_store',
        <String, Object?>{
          'key': key,
          'value': value,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[AppDatabase] Error setting key $key: $e');
    }
  }

  Future<String?> getString(String key) async {
    if (_db == null) return _memoryStore[key];

    try {
      final List<Map<String, Object?>> rows = await _db!.query(
        'key_value_store',
        columns: <String>['value'],
        where: 'key = ?',
        whereArgs: <Object>[key],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        return rows.first['value'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('[AppDatabase] Error getting key $key: $e');
      return null;
    }
  }

  Future<void> remove(String key) async {
    if (_db == null) {
      _memoryStore.remove(key);
      return;
    }

    try {
      await _db!.delete(
        'key_value_store',
        where: 'key = ?',
        whereArgs: <Object>[key],
      );
    } catch (e) {
      debugPrint('[AppDatabase] Error deleting key $key: $e');
    }
  }

  // --- BERSIHKAN SEMUA CACHE -----------------------------------------------

  Future<void> clearCache() async {
    _memoryStore.clear();
    if (_db == null) return;

    try {
      final sqflite.Batch batch = _db!.batch();
      batch.delete('categories_cache');
      batch.delete('services_cache');
      batch.delete('orders_cache');
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[AppDatabase] Error clearing cache: $e');
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
