import '../../../models/food_item_model.dart';

/// The category taxonomy for SURUH On-Demand Services.
/// Primary categories represent core services ("Bisa suruh apa saja").
const List<FoodCategoryModel> kSeedCategories = <FoodCategoryModel>[
  // --- SURUH Core Services ---
  FoodCategoryModel(id: 'antar', name: 'Suruh Antar', emoji: '🛵'),
  FoodCategoryModel(id: 'belanja', name: 'Suruh Belanja', emoji: '🛒'),
  FoodCategoryModel(id: 'makanan', name: 'Beli Makanan', emoji: '🍲'),
  FoodCategoryModel(id: 'antri', name: 'Suruh Antri', emoji: '⏱️'),
  FoodCategoryModel(id: 'bersih', name: 'Suruh Bersih', emoji: '🧹'),
  FoodCategoryModel(id: 'tukang', name: 'Suruh Tukang', emoji: '🛠️'),
  FoodCategoryModel(id: 'angkut', name: 'Suruh Angkut', emoji: '📦'),
  FoodCategoryModel(id: 'bebas', name: 'Suruh Apa Saja', emoji: '✨'),

  // --- Sub-categories / Culinary & Merchant tags ---
  FoodCategoryModel(id: 'malaysian', name: 'Kuliner Lokal', emoji: '🍛'),
  FoodCategoryModel(id: 'pizza', name: 'Pizza & Roti', emoji: '🍕'),
  FoodCategoryModel(id: 'burger', name: 'Fast Food', emoji: '🍔'),
  FoodCategoryModel(id: 'indian', name: 'Kari & Rempah', emoji: '🍲'),
  FoodCategoryModel(id: 'chinese', name: 'Oriental & Mie', emoji: '🥡'),
  FoodCategoryModel(id: 'japanese', name: 'Jepang', emoji: '🍣'),
  FoodCategoryModel(id: 'thai', name: 'Thailand', emoji: '🍜'),
  FoodCategoryModel(id: 'korean', name: 'Korea', emoji: '🍗'),
  FoodCategoryModel(id: 'desserts', name: 'Kue & Cemilan', emoji: '🍰'),
  FoodCategoryModel(id: 'drinks', name: 'Kopi & Minuman', emoji: '🧋'),
  FoodCategoryModel(id: 'healthy', name: 'Sehat & Segar', emoji: '🥗'),
];
