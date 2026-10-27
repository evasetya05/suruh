import '../../domain/entities/food_category.dart';
import '../../domain/entities/food_item.dart';

class FoodItemModel extends FoodItem {
  const FoodItemModel({
    required super.id,
    required super.restaurantId,
    required super.restaurantName,
    required super.name,
    required super.description,
    required super.priceMyr,
    required super.categoryId,
    required super.emoji,
    required super.rating,
    required super.reviewCount,
    super.discountPriceMyr,
    super.imageUrl,
    super.ingredients,
    super.allergens,
    super.isVegetarian,
    super.isSpicy,
    super.spiceLevel,
    super.calories,
    super.prepMinutes,
    super.isAvailable,
    super.isPopular,
    super.servingSize,
  });

  factory FoodItemModel.fromEntity(FoodItem f) => FoodItemModel(
        id: f.id,
        restaurantId: f.restaurantId,
        restaurantName: f.restaurantName,
        name: f.name,
        description: f.description,
        priceMyr: f.priceMyr,
        categoryId: f.categoryId,
        emoji: f.emoji,
        rating: f.rating,
        reviewCount: f.reviewCount,
        discountPriceMyr: f.discountPriceMyr,
        imageUrl: f.imageUrl,
        ingredients: f.ingredients,
        allergens: f.allergens,
        isVegetarian: f.isVegetarian,
        isSpicy: f.isSpicy,
        spiceLevel: f.spiceLevel,
        calories: f.calories,
        prepMinutes: f.prepMinutes,
        isAvailable: f.isAvailable,
        isPopular: f.isPopular,
        servingSize: f.servingSize,
      );

  factory FoodItemModel.fromJson(Map<String, dynamic> json) => FoodItemModel(
        id: json['id'] as String,
        restaurantId: json['restaurantId'] as String,
        restaurantName: json['restaurantName'] as String? ?? '',
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        priceMyr: (json['priceMyr'] as num).toDouble(),
        categoryId: json['categoryId'] as String,
        emoji: json['emoji'] as String? ?? '🍽️',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['reviewCount'] as int? ?? 0,
        discountPriceMyr: (json['discountPriceMyr'] as num?)?.toDouble(),
        imageUrl: json['imageUrl'] as String?,
        ingredients: (json['ingredients'] as List<dynamic>? ?? <dynamic>[])
            .cast<String>(),
        allergens:
            (json['allergens'] as List<dynamic>? ?? <dynamic>[]).cast<String>(),
        isVegetarian: json['isVegetarian'] as bool? ?? false,
        isSpicy: json['isSpicy'] as bool? ?? false,
        spiceLevel: json['spiceLevel'] as int? ?? 0,
        calories: json['calories'] as int?,
        prepMinutes: json['prepMinutes'] as int? ?? 15,
        isAvailable: json['isAvailable'] as bool? ?? true,
        isPopular: json['isPopular'] as bool? ?? false,
        servingSize: json['servingSize'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'restaurantId': restaurantId,
        'restaurantName': restaurantName,
        'name': name,
        'description': description,
        'priceMyr': priceMyr,
        'categoryId': categoryId,
        'emoji': emoji,
        'rating': rating,
        'reviewCount': reviewCount,
        'discountPriceMyr': discountPriceMyr,
        'imageUrl': imageUrl,
        'ingredients': ingredients,
        'allergens': allergens,
        'isVegetarian': isVegetarian,
        'isSpicy': isSpicy,
        'spiceLevel': spiceLevel,
        'calories': calories,
        'prepMinutes': prepMinutes,
        'isAvailable': isAvailable,
        'isPopular': isPopular,
        'servingSize': servingSize,
      };
}

class FoodCategoryModel extends FoodCategory {
  const FoodCategoryModel({
    required super.id,
    required super.name,
    required super.emoji,
    super.itemCount,
  });

  factory FoodCategoryModel.fromJson(Map<String, dynamic> json) =>
      FoodCategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '🍽️',
        itemCount: json['itemCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'emoji': emoji,
        'itemCount': itemCount,
      };
}
