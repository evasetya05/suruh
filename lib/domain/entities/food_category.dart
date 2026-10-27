import 'package:equatable/equatable.dart';

/// A top-level cuisine/dish category shown in the home grid.
class FoodCategory extends Equatable {
  const FoodCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.itemCount = 0,
  });

  final String id;
  final String name;
  final String emoji;
  final int itemCount;

  @override
  List<Object?> get props => <Object?>[id, name, emoji, itemCount];
}
