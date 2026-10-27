import '../../core/utils/result.dart';
import '../entities/review.dart';

abstract interface class ReviewRepository {
  Future<Result<List<Review>>> getReviewsForRestaurant(String restaurantId);

  Future<Result<List<Review>>> getReviewsForFoodItem(String foodItemId);

  Future<Result<RatingSummary>> getRatingSummary(String restaurantId);

  Future<Result<Review>> submitReview({
    required String restaurantId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
    String? foodItemId,
    List<String> orderedItems = const <String>[],
  });
}
