import 'dart:math';

import '../../../models/food_item_model.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/review_model.dart';
import 'seed_users.dart';

/// Comment templates paired with the star rating they read as.
/// `{dish}` and `{name}` are substituted per review.
const List<(int, String)> _templates = <(int, String)>[
  (5, 'The {dish} was genuinely excellent. Arrived hot, portion was generous, '
      'and the packaging held up. Ordering again this week.'),
  (5, 'Best {dish} I have had in KL, no exaggeration. Rider was early and '
      'called ahead. Five stars from me.'),
  (5, 'Consistently good. Third time ordering from {name} and the {dish} has '
      'been identical every single time.'),
  (5, 'Packaging deserves a mention - nothing leaked, everything still crisp '
      'after a 25 minute ride.'),
  (4, 'Really solid {dish}. Only note is that I asked for extra sambal and it '
      'did not make it into the bag.'),
  (4, 'Tasty and good value. Delivery took slightly longer than the estimate '
      'but the food was still warm.'),
  (4, 'Good portion for the price. The {dish} could use a bit more seasoning '
      'for my taste, but no complaints overall.'),
  (4, 'Enjoyed it. Would have given five stars if the drink had not spilled a '
      'little in transit.'),
  (3, 'Decent but not memorable. The {dish} was fine, though it arrived barely '
      'warm on a rainy evening.'),
  (3, 'Mixed experience. Food was okay, but the order was missing a side and '
      'support took a while to respond.'),
  (5, 'My family orders from {name} almost every weekend now. The {dish} is '
      'the reason.'),
  (4, 'Reliable choice for a quick lunch. Prices have crept up a bit but the '
      'quality has held.'),
  (2, 'Not my night - the {dish} was oily and lukewarm. Hoping this was a '
      'one-off, the reviews suggest it usually is.'),
  (5, 'Ordered for a small office lunch and everyone was happy. The {dish} '
      'went first.'),
  (4, 'Great flavours. A little on the spicy side if you are not used to it, '
      'so order accordingly.'),
];

/// Builds a deterministic review corpus (~8 per restaurant, ~160 total).
///
/// A fixed [Random] seed means the demo data is identical on every launch and
/// across every device, which keeps screenshots and tests stable.
List<ReviewModel> buildSeedReviews({
  required List<RestaurantModel> restaurants,
  required List<FoodItemModel> foods,
}) {
  final Random random = Random(20260731);
  final List<ReviewModel> reviews = <ReviewModel>[];
  final DateTime now = DateTime.now();

  for (final RestaurantModel restaurant in restaurants) {
    final List<FoodItemModel> menu = foods
        .where((FoodItemModel f) => f.restaurantId == restaurant.id)
        .toList(growable: false);

    // Higher-rated restaurants get more reviews, which makes the sorted lists
    // on the home screen look plausible.
    final int count = 6 + random.nextInt(4);

    for (int i = 0; i < count; i++) {
      final (String userId, String userName, String emoji) =
          kReviewerPool[random.nextInt(kReviewerPool.length)];
      final FoodItemModel dish = menu[random.nextInt(menu.length)];

      // Bias template choice toward the restaurant's own rating so a 4.9-star
      // restaurant is not full of two-star comments.
      final List<(int, String)> candidates = _templates
          .where(
            ((int, String) t) => (t.$1 - restaurant.rating).abs() <= 1.2,
          )
          .toList(growable: false);
      final (int stars, String template) =
          candidates[random.nextInt(candidates.length)];

      reviews.add(
        ReviewModel(
          id: '${restaurant.id}-rv${(i + 1).toString().padLeft(2, '0')}',
          restaurantId: restaurant.id,
          // Roughly half the reviews are attached to a specific dish so the
          // food detail page has content too.
          foodItemId: i.isEven ? dish.id : null,
          userId: userId,
          userName: userName,
          userAvatarEmoji: emoji,
          rating: stars.toDouble(),
          comment: template
              .replaceAll('{dish}', dish.name)
              .replaceAll('{name}', restaurant.name),
          createdAt: now.subtract(
            Duration(
              days: random.nextInt(120),
              hours: random.nextInt(24),
              minutes: random.nextInt(60),
            ),
          ),
          likes: random.nextInt(48),
          orderedItems: <String>[dish.name],
        ),
      );
    }
  }

  reviews.sort(
    (ReviewModel a, ReviewModel b) => b.createdAt.compareTo(a.createdAt),
  );
  return reviews;
}
