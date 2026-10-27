import 'package:equatable/equatable.dart';

import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../../core/utils/result.dart';
import '../entities/review.dart';
import '../repositories/order_repository.dart';
import '../repositories/review_repository.dart';

class GetRestaurantReviews extends UseCase<List<Review>, String> {
  const GetRestaurantReviews(this._repository);

  final ReviewRepository _repository;

  @override
  Future<Result<List<Review>>> call(String restaurantId) =>
      _repository.getReviewsForRestaurant(restaurantId);
}

class SubmitReviewParams extends Equatable {
  const SubmitReviewParams({
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.orderId,
    this.foodItemId,
    this.orderedItems = const <String>[],
  });

  final String restaurantId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;

  /// When supplied, the order is flagged as rated so the prompt stops showing.
  final String? orderId;
  final String? foodItemId;
  final List<String> orderedItems;

  @override
  List<Object?> get props =>
      <Object?>[restaurantId, userId, rating, comment, orderId, foodItemId];
}

class SubmitReview extends UseCase<Review, SubmitReviewParams> {
  const SubmitReview(this._reviews, this._orders);

  final ReviewRepository _reviews;
  final OrderRepository _orders;

  @override
  Future<Result<Review>> call(SubmitReviewParams params) async {
    if (params.rating < 1 || params.rating > 5) {
      return const Result<Review>.failure(
        ValidationFailure('Please pick a rating between 1 and 5 stars.'),
      );
    }
    if (params.comment.trim().length < 3) {
      return const Result<Review>.failure(
        ValidationFailure('Tell us a little more about your experience.'),
      );
    }

    final Result<Review> result = await _reviews.submitReview(
      restaurantId: params.restaurantId,
      userId: params.userId,
      userName: params.userName,
      rating: params.rating,
      comment: params.comment.trim(),
      foodItemId: params.foodItemId,
      orderedItems: params.orderedItems,
    );

    if (result.isSuccess && params.orderId != null) {
      await _orders.markRated(params.orderId!);
    }
    return result;
  }
}
