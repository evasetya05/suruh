import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.foodItemId,
    this.userAvatarEmoji = '🙂',
    this.likes = 0,
    this.orderedItems = const <String>[],
  });

  final String id;
  final String restaurantId;

  /// Set when the review is about a specific dish rather than the restaurant.
  final String? foodItemId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String userAvatarEmoji;
  final int likes;

  /// Dish names quoted under the review, as on Grab.
  final List<String> orderedItems;

  @override
  List<Object?> get props => <Object?>[
        id,
        restaurantId,
        foodItemId,
        userId,
        rating,
        comment,
        createdAt,
        likes,
      ];
}

/// Aggregated rating breakdown for a restaurant's review tab.
class RatingSummary extends Equatable {
  const RatingSummary({
    required this.average,
    required this.total,
    required this.distribution,
  });

  final double average;
  final int total;

  /// Star value (1-5) to number of reviews.
  final Map<int, int> distribution;

  factory RatingSummary.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) {
      return const RatingSummary(
        average: 0,
        total: 0,
        distribution: <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }
    final Map<int, int> distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double sum = 0;
    for (final Review review in reviews) {
      sum += review.rating;
      final int bucket = review.rating.round().clamp(1, 5);
      distribution[bucket] = (distribution[bucket] ?? 0) + 1;
    }
    return RatingSummary(
      average: sum / reviews.length,
      total: reviews.length,
      distribution: distribution,
    );
  }

  double fractionFor(int star) =>
      total == 0 ? 0 : (distribution[star] ?? 0) / total;

  @override
  List<Object?> get props => <Object?>[average, total, distribution];
}
