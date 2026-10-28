import 'package:flutter_test/flutter_test.dart';
import 'package:suruh/core/storage/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDatabase (SQLite cache & offline storage)', () {
    final AppDatabase db = AppDatabase.instance;

    setUp(() async {
      await db.init();
      await db.clearCache();
    });

    test('cacheCategories & getCachedCategories works', () async {
      final List<Map<String, dynamic>> testCategories = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'antar-barang',
          'slug': 'antar-barang',
          'name': 'Antar Barang',
          'emoji': '📦',
          'item_count': 5,
        },
        <String, dynamic>{
          'id': 'belanja-pasar',
          'slug': 'belanja-pasar',
          'name': 'Belanja Pasar Flamboyan',
          'emoji': '🛒',
          'item_count': 8,
        },
      ];

      await db.cacheCategories(testCategories);
      final List<Map<String, dynamic>> loaded = await db.getCachedCategories();

      expect(loaded.length, 2);
      expect(loaded.any((Map<String, dynamic> c) => c['name'] == 'Antar Barang'), isTrue);
      expect(loaded.any((Map<String, dynamic> c) => c['name'] == 'Belanja Pasar Flamboyan'), isTrue);
    });

    test('cacheServices & getCachedServices works', () async {
      final List<Map<String, dynamic>> testServices = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'svc-1',
          'category_slug': 'antar-barang',
          'name': 'Kirim Dokumen Cepat',
          'price': 15000.0,
        },
        <String, dynamic>{
          'id': 'svc-2',
          'category_slug': 'belanja-pasar',
          'name': 'Belanja Sayur Segar',
          'price': 25000.0,
        },
      ];

      await db.cacheServices(testServices);

      final List<Map<String, dynamic>> allServices = await db.getCachedServices();
      expect(allServices.length, 2);

      final List<Map<String, dynamic>> filtered =
          await db.getCachedServices(categorySlug: 'antar-barang');
      expect(filtered.length, 1);
      expect(filtered.first['name'], 'Kirim Dokumen Cepat');
    });

    test('cacheOrder & getCachedOrders works', () async {
      final Map<String, dynamic> order = <String, dynamic>{
        'id': 'ord-ptk-101',
        'status': 'preparing',
        'total': 45000.0,
      };

      await db.cacheOrder(order);
      final List<Map<String, dynamic>> orders = await db.getCachedOrders();

      expect(orders.length, 1);
      expect(orders.first['id'], 'ord-ptk-101');
      expect(orders.first['status'], 'preparing');
    });

    test('setString & getString works', () async {
      await db.setString('test_key', 'test_value');
      final String? val = await db.getString('test_key');
      expect(val, 'test_value');

      await db.remove('test_key');
      final String? valAfterDelete = await db.getString('test_key');
      expect(valAfterDelete, isNull);
    });
  });
}
