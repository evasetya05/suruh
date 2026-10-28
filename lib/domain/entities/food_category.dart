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

const List<FoodCategory> kServiceCategories = <FoodCategory>[
  FoodCategory(id: 'titip-belanja', name: 'Titip & Belanja', emoji: '🛒'),
  FoodCategory(id: 'antar-dokumen', name: 'Antar Dokumen', emoji: '📄'),
  FoodCategory(id: 'bantu-antre', name: 'Bantu Antre & Urusan', emoji: '⏳'),
  FoodCategory(id: 'bersih-rumah', name: 'Bersih Rumah & AC', emoji: '🧹'),
  FoodCategory(id: 'angkut-barang', name: 'Angkut Barang & Pindahan', emoji: '🚚'),
  FoodCategory(id: 'servis-elektronik', name: 'Servis & Perbaikan', emoji: '🔧'),
  FoodCategory(id: 'umum', name: 'Layanan Umum', emoji: '⚡'),
];
