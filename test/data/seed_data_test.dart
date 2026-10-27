import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_categories.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_foods.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_orders.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_promos.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_restaurants.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_reviews.dart';
import 'package:food_delivery_app/data/datasources/local/seed/seed_users.dart';
import 'package:food_delivery_app/data/models/food_item_model.dart';
import 'package:food_delivery_app/data/models/order_model.dart';
import 'package:food_delivery_app/data/models/restaurant_model.dart';
import 'package:food_delivery_app/data/models/review_model.dart';
import 'package:food_delivery_app/domain/entities/order.dart';
import 'package:food_delivery_app/domain/entities/user.dart';

/// The demo backend is the app's only data source out of the box, so the seed
/// corpus is treated as production data and asserted on: broken references here
/// would surface as empty screens rather than errors.
void main() {
  final List<FoodItemModel> foods = buildSeedFoods();
  final List<ReviewModel> reviews =
      buildSeedReviews(restaurants: kSeedRestaurants, foods: foods);
  final List<OrderModel> orders =
      buildSeedOrders(restaurants: kSeedRestaurants, foods: foods);

  group('Catalogue size', () {
    test('ships exactly 20 restaurants', () {
      expect(kSeedRestaurants, hasLength(20));
    });

    test('ships exactly 100 dishes', () {
      expect(foods, hasLength(100));
    });

    test('every restaurant has a menu', () {
      for (final RestaurantModel restaurant in kSeedRestaurants) {
        final Iterable<FoodItemModel> menu =
            foods.where((FoodItemModel f) => f.restaurantId == restaurant.id);
        expect(
          menu,
          isNotEmpty,
          reason: '${restaurant.name} (${restaurant.id}) has no dishes',
        );
      }
    });
  });

  group('Referential integrity', () {
    test('restaurant ids are unique', () {
      final Set<String> ids =
          kSeedRestaurants.map((RestaurantModel r) => r.id).toSet();
      expect(ids, hasLength(kSeedRestaurants.length));
    });

    test('dish ids are unique', () {
      final Set<String> ids = foods.map((FoodItemModel f) => f.id).toSet();
      expect(ids, hasLength(foods.length));
    });

    test('every dish points at a real restaurant and category', () {
      final Set<String> restaurantIds =
          kSeedRestaurants.map((RestaurantModel r) => r.id).toSet();
      final Set<String> categoryIds =
          kSeedCategories.map((dynamic c) => c.id as String).toSet();

      for (final FoodItemModel food in foods) {
        expect(restaurantIds, contains(food.restaurantId));
        expect(
          categoryIds,
          contains(food.categoryId),
          reason: '${food.name} uses unknown category "${food.categoryId}"',
        );
      }
    });

    test('every review points at a real restaurant', () {
      final Set<String> restaurantIds =
          kSeedRestaurants.map((RestaurantModel r) => r.id).toSet();
      for (final ReviewModel review in reviews) {
        expect(restaurantIds, contains(review.restaurantId));
      }
    });

    test('dish-level reviews point at a real dish', () {
      final Set<String> foodIds = foods.map((FoodItemModel f) => f.id).toSet();
      for (final ReviewModel review
          in reviews.where((ReviewModel r) => r.foodItemId != null)) {
        expect(foodIds, contains(review.foodItemId));
      }
    });
  });

  group('Data sanity', () {
    test('prices are positive and offers are genuinely cheaper', () {
      for (final FoodItemModel food in foods) {
        expect(food.priceMyr, greaterThan(0), reason: food.name);
        if (food.discountPriceMyr != null) {
          expect(
            food.discountPriceMyr,
            lessThan(food.priceMyr),
            reason: '${food.name} offer price is not a discount',
          );
        }
      }
    });

    test('ratings sit within 0-5 and ETAs are ordered', () {
      for (final RestaurantModel r in kSeedRestaurants) {
        expect(r.rating, inInclusiveRange(0, 5));
        expect(r.etaMinMinutes, lessThanOrEqualTo(r.etaMaxMinutes));
        expect(r.deliveryFeeMyr, greaterThanOrEqualTo(0));
      }
    });

    test('at least one restaurant is promoted so the home rail fills', () {
      expect(
        kSeedRestaurants.where((RestaurantModel r) => r.isPromoted),
        isNotEmpty,
      );
    });

    test('there are discounted dishes for the offers rail', () {
      expect(foods.where((FoodItemModel f) => f.isOnOffer), isNotEmpty);
    });

    test('there are popular dishes for the popular rail', () {
      expect(foods.where((FoodItemModel f) => f.isPopular), isNotEmpty);
    });
  });

  group('Personas and orders', () {
    test('one account exists for each role', () {
      for (final UserRole role in UserRole.values) {
        expect(
          kSeedUsers.where((dynamic u) => u.role == role),
          hasLength(1),
          reason: 'missing a seeded ${role.label} account',
        );
      }
    });

    test('the partner persona manages a real restaurant', () {
      final dynamic partner = kSeedUsers
          .firstWhere((dynamic u) => u.role == UserRole.restaurantPartner);
      expect(partner.managedRestaurantId, isNotNull);
      expect(
        kSeedRestaurants.where(
          (RestaurantModel r) => r.id == partner.managedRestaurantId,
        ),
        isNotEmpty,
      );
      expect(
        kSeedRestaurants
            .firstWhere(
              (RestaurantModel r) => r.id == partner.managedRestaurantId,
            )
            .ownerId,
        partner.id,
      );
    });

    test('the customer has order history and a live order to track', () {
      final Iterable<OrderModel> mine =
          orders.where((OrderModel o) => o.userId == 'u-customer');

      expect(mine.where((OrderModel o) => o.status.isTerminal), isNotEmpty);
      expect(mine.where((OrderModel o) => o.isActive), isNotEmpty);
    });

    test("the partner's three queues are all populated", () {
      final Iterable<OrderModel> partnerOrders =
          orders.where((OrderModel o) => o.restaurantId == 'r-06');

      expect(
        partnerOrders.where((OrderModel o) => o.status == OrderStatus.placed),
        isNotEmpty,
      );
      expect(
        partnerOrders.where(
          (OrderModel o) => !o.status.isTerminal && o.status != OrderStatus.placed,
        ),
        isNotEmpty,
      );
      expect(
        partnerOrders.where((OrderModel o) => o.status.isTerminal),
        isNotEmpty,
      );
    });

    test('order totals match their line items and fees', () {
      for (final OrderModel order in orders) {
        final double expected = order.subtotal +
            order.deliveryFee +
            order.serviceFee -
            order.discount;
        expect(
          order.total,
          closeTo(expected < 0 ? 0 : expected, 0.01),
          reason: 'order ${order.id} total does not reconcile',
        );
      }
    });

    test('orders past the kitchen have a rider assigned', () {
      final Iterable<OrderModel> shipped = orders.where(
        (OrderModel o) =>
            o.status == OrderStatus.outForDelivery ||
            o.status == OrderStatus.delivered,
      );
      for (final OrderModel order in shipped) {
        expect(order.rider, isNotNull, reason: 'order ${order.id} has no rider');
      }
    });
  });

  group('Promos', () {
    test('codes are unique and upper case', () {
      final Set<String> codes = kSeedPromos.map((dynamic p) => p.code as String).toSet();
      expect(codes, hasLength(kSeedPromos.length));
      for (final String code in codes) {
        expect(code, code.toUpperCase());
      }
    });

    test('there is at least one live promo and one expired one to demo', () {
      expect(kSeedPromos.where((dynamic p) => !(p.isExpired as bool)), isNotEmpty);
      expect(kSeedPromos.where((dynamic p) => p.isExpired as bool), isNotEmpty);
    });
  });

  group('Determinism', () {
    test('the review corpus is identical across builds', () {
      final List<ReviewModel> again =
          buildSeedReviews(restaurants: kSeedRestaurants, foods: foods);

      expect(again, hasLength(reviews.length));
      expect(
        again.map((ReviewModel r) => r.id).toList(),
        reviews.map((ReviewModel r) => r.id).toList(),
      );
    });
  });
}
