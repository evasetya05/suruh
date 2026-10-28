import '../../core/storage/local_storage.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl({required LocalStorage storage}) : _storage = storage;

  final LocalStorage _storage;
  static const String _kReviewsKey = 'suruh_customer_reviews';

  @override
  Future<Result<List<Review>>> getReviewsForRestaurant(String restaurantId) =>
      guard<List<Review>>(() async {
        final List<ReviewModel> all = _loadReviews();
        return all.where((ReviewModel r) => r.restaurantId == restaurantId).toList();
      });

  @override
  Future<Result<List<Review>>> getReviewsForFoodItem(String foodItemId) =>
      guard<List<Review>>(() async {
        final List<ReviewModel> all = _loadReviews();
        return all.where((ReviewModel r) => r.foodItemId == foodItemId).toList();
      });

  @override
  Future<Result<RatingSummary>> getRatingSummary(String restaurantId) {
    return guard<RatingSummary>(() async {
      final List<ReviewModel> reviews = (await getReviewsForRestaurant(restaurantId))
          .fold((_) => <Review>[], (List<Review> r) => r)
          .cast<ReviewModel>();
      if (reviews.isEmpty) {
        return const RatingSummary(
          average: 5.0,
          total: 0,
          distribution: <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        );
      }
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

      final List<Map<String, dynamic>> raw = _storage.readJsonList(_kReviewsKey);
      raw.insert(0, review.toJson());
      await _storage.writeJsonList(_kReviewsKey, raw);
      return review;
    });
  }

  List<ReviewModel> _loadReviews() {
    final List<Map<String, dynamic>> raw = _storage.readJsonList(_kReviewsKey);
    return raw.map((Map<String, dynamic> j) => ReviewModel.fromJson(j)).toList();
  }
}
