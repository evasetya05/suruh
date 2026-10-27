import '../../core/utils/result.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/local/demo_data_source.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl({required DemoDataSource remote}) : _remote = remote;

  final DemoDataSource _remote;

  @override
  Future<Result<List<Review>>> getReviewsForRestaurant(String restaurantId) =>
      guard<List<Review>>(
        () => _remote.getReviewsForRestaurant(restaurantId),
      );

  @override
  Future<Result<List<Review>>> getReviewsForFoodItem(String foodItemId) =>
      guard<List<Review>>(() => _remote.getReviewsForFood(foodItemId));

  @override
  Future<Result<RatingSummary>> getRatingSummary(String restaurantId) {
    return guard<RatingSummary>(() async {
      final List<ReviewModel> reviews =
          await _remote.getReviewsForRestaurant(restaurantId);
      return RatingSummary.fromReviews(reviews);
    });
  }

  @override
  Future<Result<Review>> submitReview({
    required String restaurantId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
    String? foodItemId,
    List<String> orderedItems = const <String>[],
  }) {
    return guard<Review>(() async {
      final ReviewModel review = ReviewModel(
        id: 'rv-${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        foodItemId: foodItemId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        orderedItems: orderedItems,
      );
      return _remote.addReview(review);
    });
  }
}
