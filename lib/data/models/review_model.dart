import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.restaurantId,
    required super.userId,
    required super.userName,
    required super.rating,
    required super.comment,
    required super.createdAt,
    super.foodItemId,
    super.userAvatarEmoji,
    super.likes,
    super.orderedItems,
  });

  factory ReviewModel.fromEntity(Review r) => ReviewModel(
        id: r.id,
        restaurantId: r.restaurantId,
        userId: r.userId,
        userName: r.userName,
        rating: r.rating,
        comment: r.comment,
        createdAt: r.createdAt,
        foodItemId: r.foodItemId,
        userAvatarEmoji: r.userAvatarEmoji,
        likes: r.likes,
        orderedItems: r.orderedItems,
      );

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['id'] as String,
        restaurantId: json['restaurantId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        rating: (json['rating'] as num).toDouble(),
        comment: json['comment'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        foodItemId: json['foodItemId'] as String?,
        userAvatarEmoji: json['userAvatarEmoji'] as String? ?? '🙂',
        likes: json['likes'] as int? ?? 0,
        orderedItems: (json['orderedItems'] as List<dynamic>? ?? <dynamic>[])
            .cast<String>(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'restaurantId': restaurantId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'foodItemId': foodItemId,
        'userAvatarEmoji': userAvatarEmoji,
        'likes': likes,
        'orderedItems': orderedItems,
      };
}
