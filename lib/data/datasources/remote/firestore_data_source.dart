import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/error/exceptions.dart';
import '../../models/food_item_model.dart';
import '../../models/order_model.dart';
import '../../models/promo_model.dart';
import '../../models/restaurant_model.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';

/// Firestore/Storage/Functions access, mirroring [DemoDataSource]'s surface.
///
/// The repositories in `lib/data/repositories/` are written against that shared
/// surface, so swapping `Backend.demo` for `Backend.firebase` in
/// [AppConfig] is the only change needed to run against a live project.
///
/// Collection layout (see `firebase/firestore.rules`):
///
/// ```text
/// users/{uid}
/// restaurants/{restaurantId}
/// restaurants/{restaurantId}/menu/{foodItemId}
/// orders/{orderId}
/// reviews/{reviewId}
/// promos/{promoId}
/// ```
class FirestoreDataSource {
  FirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  static const String usersPath = 'users';
  static const String restaurantsPath = 'restaurants';
  static const String menuPath = 'menu';
  static const String ordersPath = 'orders';
  static const String reviewsPath = 'reviews';
  static const String promosPath = 'promos';

  // --- Catalogue ------------------------------------------------------------

  Future<List<RestaurantModel>> getRestaurants() async {
    return _read(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _db.collection(restaurantsPath).get();
      return snapshot.docs.map(_restaurantFrom).toList(growable: false);
    });
  }

  Future<RestaurantModel> getRestaurantById(String id) async {
    return _read(() async {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection(restaurantsPath).doc(id).get();
      if (!doc.exists) throw NotFoundException('No restaurant "$id"');
      return _restaurantFrom(doc);
    });
  }

  Future<RestaurantModel> getRestaurantByOwner(String ownerId) async {
    return _read(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection(restaurantsPath)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        throw NotFoundException('No restaurant owned by "$ownerId"');
      }
      return _restaurantFrom(snapshot.docs.first);
    });
  }

  Future<List<FoodItemModel>> getMenu(String restaurantId) async {
    return _read(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection(restaurantsPath)
          .doc(restaurantId)
          .collection(menuPath)
          .get();
      return snapshot.docs.map(_foodFrom).toList(growable: false);
    });
  }

  /// Collection-group query so "all dishes" does not need N reads.
  Future<List<FoodItemModel>> getFoods() async {
    return _read(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _db.collectionGroup(menuPath).get();
      return snapshot.docs.map(_foodFrom).toList(growable: false);
    });
  }

  Future<FoodItemModel> getFoodById(String restaurantId, String id) async {
    return _read(() async {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _db
          .collection(restaurantsPath)
          .doc(restaurantId)
          .collection(menuPath)
          .doc(id)
          .get();
      if (!doc.exists) throw NotFoundException('No dish "$id"');
      return _foodFrom(doc);
    });
  }

  Future<List<PromoModel>> getPromos() async {
    return _read(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection(promosPath)
          .where('active', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              PromoModel.fromJson(<String, dynamic>{'id': d.id, ...d.data()}))
          .toList(growable: false);
    });
  }

  // --- Reviews --------------------------------------------------------------

  Future<List<ReviewModel>> getReviewsForRestaurant(String restaurantId) async {
    return _read(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection(reviewsPath)
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      return snapshot.docs.map(_reviewFrom).toList(growable: false);
    });
  }

  Future<List<ReviewModel>> getReviewsForFood(String foodItemId) async {
    return _read(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection(reviewsPath)
          .where('foodItemId', isEqualTo: foodItemId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snapshot.docs.map(_reviewFrom).toList(growable: false);
    });
  }

  /// Writes the review, then lets a Cloud Function recompute the restaurant's
  /// aggregate rating - doing it client-side would be racy under concurrency.
  Future<ReviewModel> addReview(ReviewModel review) async {
    return _read(() async {
      await _db.collection(reviewsPath).doc(review.id).set(review.toJson());
      await _functions.httpsCallable('recomputeRestaurantRating').call<void>(
        <String, dynamic>{'restaurantId': review.restaurantId},
      );
      return review;
    });
  }

  // --- Users ----------------------------------------------------------------

  Future<UserModel?> getUserById(String id) async {
    return _read(() async {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection(usersPath).doc(id).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(<String, dynamic>{'id': doc.id, ...doc.data()!});
    });
  }

  Future<UserModel> upsertUser(UserModel user) async {
    return _read(() async {
      await _db
          .collection(usersPath)
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
      return user;
    });
  }

  // --- Orders ---------------------------------------------------------------

  Future<OrderModel> createOrder(OrderModel order) async {
    return _read(() async {
      // `placeOrder` validates prices server-side, charges the wallet and
      // fans out an FCM notification to the restaurant.
      await _functions.httpsCallable('placeOrder').call<void>(order.toJson());
      return order;
    });
  }

  Future<OrderModel> getOrderById(String id) async {
    return _read(() async {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection(ordersPath).doc(id).get();
      if (!doc.exists) throw NotFoundException('No order "$id"');
      return _orderFrom(doc);
    });
  }

  Stream<OrderModel> watchOrder(String id) => _db
      .collection(ordersPath)
      .doc(id)
      .snapshots()
      .where((DocumentSnapshot<Map<String, dynamic>> d) => d.exists)
      .map(_orderFrom);

  Stream<List<OrderModel>> watchOrdersForRestaurant(String restaurantId) => _db
      .collection(ordersPath)
      .where('restaurantId', isEqualTo: restaurantId)
      .orderBy('placedAt', descending: true)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> s) =>
            s.docs.map(_orderFrom).toList(growable: false),
      );

  Stream<List<OrderModel>> watchOrdersForUser(String userId) => _db
      .collection(ordersPath)
      .where('userId', isEqualTo: userId)
      .orderBy('placedAt', descending: true)
      .snapshots()
      .map(
        (QuerySnapshot<Map<String, dynamic>> s) =>
            s.docs.map(_orderFrom).toList(growable: false),
      );

  Future<OrderModel> updateOrder(OrderModel order) async {
    return _read(() async {
      await _db.collection(ordersPath).doc(order.id).update(order.toJson());
      return order;
    });
  }

  // --- Partner menu management ---------------------------------------------

  Future<FoodItemModel> upsertFood(FoodItemModel item) async {
    return _read(() async {
      await _db
          .collection(restaurantsPath)
          .doc(item.restaurantId)
          .collection(menuPath)
          .doc(item.id)
          .set(item.toJson(), SetOptions(merge: true));
      return item;
    });
  }

  Future<void> deleteFood(String restaurantId, String foodItemId) async {
    return _read(() async {
      await _db
          .collection(restaurantsPath)
          .doc(restaurantId)
          .collection(menuPath)
          .doc(foodItemId)
          .delete();
    });
  }

  Future<RestaurantModel> updateRestaurant(RestaurantModel restaurant) async {
    return _read(() async {
      await _db
          .collection(restaurantsPath)
          .doc(restaurant.id)
          .set(restaurant.toJson(), SetOptions(merge: true));
      return restaurant;
    });
  }

  // --- Storage --------------------------------------------------------------

  /// Uploads a dish photo and returns its public download URL.
  Future<String> uploadDishImage({
    required String restaurantId,
    required String foodItemId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    return _read(() async {
      final Reference ref = _storage
          .ref()
          .child('restaurants/$restaurantId/menu/$foodItemId.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return ref.getDownloadURL();
    });
  }

  // --- Mapping --------------------------------------------------------------

  RestaurantModel _restaurantFrom(DocumentSnapshot<Map<String, dynamic>> doc) =>
      RestaurantModel.fromJson(<String, dynamic>{'id': doc.id, ...doc.data()!});

  FoodItemModel _foodFrom(DocumentSnapshot<Map<String, dynamic>> doc) =>
      FoodItemModel.fromJson(<String, dynamic>{'id': doc.id, ...doc.data()!});

  ReviewModel _reviewFrom(DocumentSnapshot<Map<String, dynamic>> doc) =>
      ReviewModel.fromJson(<String, dynamic>{'id': doc.id, ...doc.data()!});

  OrderModel _orderFrom(DocumentSnapshot<Map<String, dynamic>> doc) =>
      OrderModel.fromJson(<String, dynamic>{'id': doc.id, ...doc.data()!});

  /// Translates Firebase's platform exceptions into this app's exception types
  /// so repositories keep working against one error contract.
  Future<T> _read<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (error) {
      throw switch (error.code) {
        'unavailable' || 'deadline-exceeded' => NetworkException(
            'Cannot reach the server right now.',
            error,
          ),
        'not-found' => NotFoundException(error.message ?? 'Not found', error),
        'permission-denied' => ServerException(
            'You do not have access to this data.',
            error,
          ),
        _ => ServerException(error.message ?? 'Firestore error', error),
      };
    }
  }
}
