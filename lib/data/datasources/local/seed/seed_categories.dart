import '../../../models/food_item_model.dart';

/// The category taxonomy. Ids are stable strings because they are referenced by
/// every [FoodItemModel] and persisted in the local cache.
const List<FoodCategoryModel> kSeedCategories = <FoodCategoryModel>[
  FoodCategoryModel(id: 'malaysian', name: 'Malaysian', emoji: '🍛'),
  FoodCategoryModel(id: 'pizza', name: 'Pizza', emoji: '🍕'),
  FoodCategoryModel(id: 'burger', name: 'Burger', emoji: '🍔'),
  FoodCategoryModel(id: 'indian', name: 'Indian', emoji: '🍲'),
  FoodCategoryModel(id: 'chinese', name: 'Chinese', emoji: '🥡'),
  FoodCategoryModel(id: 'japanese', name: 'Japanese', emoji: '🍣'),
  FoodCategoryModel(id: 'thai', name: 'Thai', emoji: '🍜'),
  FoodCategoryModel(id: 'korean', name: 'Korean', emoji: '🍗'),
  FoodCategoryModel(id: 'desserts', name: 'Desserts', emoji: '🍰'),
  FoodCategoryModel(id: 'drinks', name: 'Drinks', emoji: '🧋'),
  FoodCategoryModel(id: 'healthy', name: 'Healthy', emoji: '🥗'),
];
