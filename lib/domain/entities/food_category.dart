import 'package:equatable/equatable.dart';

/// A service category shown in the landing page filter.
/// Loaded dynamically from backend API (/api/v1/services/categories/).
class FoodCategory extends Equatable {
  const FoodCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.itemCount = 0,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    final String name = json['name']?.toString() ?? 'Layanan';
    final String slug = json['slug']?.toString() ?? json['id']?.toString() ?? '';
    final String? icon = json['icon']?.toString();
    final int count = (json['active_services_count'] as num?)?.toInt() ??
        (json['item_count'] as num?)?.toInt() ??
        0;

    String emoji = '⚡';
    if (icon != null && icon.trim().isNotEmpty && icon.runes.length <= 2) {
      emoji = icon.trim();
    } else {
      final String lower = '${name.toLowerCase()} ${slug.toLowerCase()}';
      if (lower.contains('belanja') || lower.contains('titip') || lower.contains('pasar')) {
        emoji = '🛒';
      } else if (lower.contains('dokumen') || lower.contains('surat')) {
        emoji = '📄';
      } else if (lower.contains('bersih') || lower.contains('rumah') || lower.contains('ac')) {
        emoji = '🧹';
      } else if (lower.contains('antre') || lower.contains('bantu')) {
        emoji = '⏳';
      } else if (lower.contains('angkut') || lower.contains('pindah')) {
        emoji = '🚚';
      } else if (lower.contains('servis') || lower.contains('perbaikan')) {
        emoji = '🔧';
      }
    }

    return FoodCategory(
      id: slug,
      name: name,
      emoji: emoji,
      itemCount: count,
    );
  }

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
