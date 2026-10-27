import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.name,
    required this.description,
    required this.priceMyr,
    required this.categoryId,
    required this.emoji,
    required this.rating,
    required this.reviewCount,
    this.discountPriceMyr,
    this.imageUrl,
    this.ingredients = const <String>[],
    this.allergens = const <String>[],
    this.isVegetarian = false,
    this.isSpicy = false,
    this.spiceLevel = 0,
    this.calories,
    this.prepMinutes = 15,
    this.isAvailable = true,
    this.isPopular = false,
    this.servingSize,
  });

  final String id;
  final String restaurantId;
  final String restaurantName;
  final String name;
  final String description;
  final double priceMyr;

  /// When set and lower than [priceMyr], the item is on offer.
  final double? discountPriceMyr;
  final String categoryId;
  final String emoji;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final List<String> ingredients;
  final List<String> allergens;
  final bool isVegetarian;
  final bool isSpicy;

  /// 0-3 chillies.
  final int spiceLevel;
  final int? calories;
  final int prepMinutes;
  final bool isAvailable;
  final bool isPopular;
  final String? servingSize;

  bool get isOnOffer =>
      discountPriceMyr != null && discountPriceMyr! < priceMyr;

  /// The price a customer actually pays.
  double get effectivePrice => isOnOffer ? discountPriceMyr! : priceMyr;

  int get discountPercent => isOnOffer
      ? (((priceMyr - discountPriceMyr!) / priceMyr) * 100).round()
      : 0;

  FoodItem copyWith({
    String? name,
    String? description,
    double? priceMyr,
    double? discountPriceMyr,
    bool clearDiscount = false,
    String? categoryId,
    String? emoji,
    List<String>? ingredients,
    bool? isVegetarian,
    bool? isSpicy,
    int? spiceLevel,
    int? calories,
    int? prepMinutes,
    bool? isAvailable,
    bool? isPopular,
  }) {
    return FoodItem(
      id: id,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      name: name ?? this.name,
      description: description ?? this.description,
      priceMyr: priceMyr ?? this.priceMyr,
      discountPriceMyr:
          clearDiscount ? null : (discountPriceMyr ?? this.discountPriceMyr),
      categoryId: categoryId ?? this.categoryId,
      emoji: emoji ?? this.emoji,
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: imageUrl,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isSpicy: isSpicy ?? this.isSpicy,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      calories: calories ?? this.calories,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      isAvailable: isAvailable ?? this.isAvailable,
      isPopular: isPopular ?? this.isPopular,
      servingSize: servingSize,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        restaurantId,
        name,
        description,
        priceMyr,
        discountPriceMyr,
        categoryId,
        rating,
        reviewCount,
        isAvailable,
        isPopular,
        isVegetarian,
      ];
}
