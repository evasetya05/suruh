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
    this.priceDisplay,
    this.whatsappNumber,
    this.whatsappUrl,
    this.availableCities = const <String>[],
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? json['slug']?.toString() ?? '';
    final String name = json['name']?.toString() ?? 'Layanan SURUH';
    final String catName = json['category_name']?.toString() ?? 'Umum';
    final String catSlug = json['category_slug']?.toString() ?? 'umum';
    final String shortDesc = json['short_description']?.toString() ?? '';
    final String fullDesc = json['description']?.toString() ?? '';
    final String desc = shortDesc.isNotEmpty ? shortDesc : fullDesc;

    double price = 0.0;
    if (json['pricing_configuration'] is Map) {
      final Map<String, dynamic> p =
          json['pricing_configuration'] as Map<String, dynamic>;
      price = (p['base_price'] as num?)?.toDouble() ??
          (p['minimum_price'] as num?)?.toDouble() ??
          0.0;
    }

    final String? priceDisplay = json['price_display']?.toString();
    final String? whatsappNumber = json['whatsapp_number']?.toString();
    final String? whatsappUrl = json['whatsapp_url']?.toString();
    final String? iconStr = json['icon']?.toString();

    List<String> cities = const <String>[];
    if (json['available_cities'] is List) {
      cities = (json['available_cities'] as List<dynamic>)
          .map((dynamic c) => c.toString())
          .toList();
    }

    String emoji = '⚡';
    if (iconStr != null && iconStr.trim().isNotEmpty && iconStr.runes.length <= 2) {
      emoji = iconStr.trim();
    } else {
      final String lower = '${name.toLowerCase()} ${catSlug.toLowerCase()}';
      if (lower.contains('belanja') ||
          lower.contains('titip') ||
          lower.contains('pasar')) {
        emoji = '🛒';
      } else if (lower.contains('dokumen') || lower.contains('surat')) {
        emoji = '📄';
      } else if (lower.contains('bersih') ||
          lower.contains('rumah') ||
          lower.contains('ac')) {
        emoji = '🧹';
      } else if (lower.contains('antre') || lower.contains('bantu')) {
        emoji = '⏳';
      } else if (lower.contains('angkut') || lower.contains('pindah')) {
        emoji = '🚚';
      } else if (lower.contains('servis') || lower.contains('perbaikan')) {
        emoji = '🔧';
      }
    }

    return FoodItem(
      id: id,
      restaurantId: 'prov-$catSlug',
      restaurantName: catName,
      name: name,
      description: desc,
      priceMyr: price,
      imageUrl: (iconStr != null && iconStr.startsWith('http')) ? iconStr : null,
      priceDisplay: (priceDisplay != null && priceDisplay.trim().isNotEmpty)
          ? priceDisplay
          : null,
      whatsappNumber: whatsappNumber,
      whatsappUrl: whatsappUrl,
      availableCities: cities,
      categoryId: catSlug,
      emoji: emoji,
      rating: 5.0,
      reviewCount: 0,
      isPopular: true,
      isAvailable: true,
    );
  }

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
  final String? priceDisplay;
  final String? whatsappNumber;
  final String? whatsappUrl;
  final List<String> availableCities;

  bool isAvailableInCity(String citySlug) {
    if (availableCities.isEmpty) return true;
    return availableCities.contains(citySlug);
  }

  /// Format string harga agar selalu memiliki separator ribuan (titik) dan prefix Rp jika angka.
  static String formatRupiah(String? raw, {double fallback = 0}) {
    if (raw == null || raw.trim().isEmpty) {
      final int amount = fallback.toInt();
      final String formatted = amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return 'Rp $formatted';
    }

    String text = raw.trim();

    // Format angka 4 digit atau lebih yang belum memiliki separator titik
    text = text.replaceAllMapped(RegExp(r'\b(\d{4,})\b'), (Match m) {
      final String digits = m[1]!;
      return digits.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m2) => '${m2[1]}.',
      );
    });

    // Tambahkan "Rp" jika memiliki angka dan belum ada kata Rp
    final bool hasDigits = RegExp(r'\d').hasMatch(text);
    final bool hasRp = RegExp(r'rp', caseSensitive: false).hasMatch(text);

    if (hasDigits && !hasRp) {
      if (text.toLowerCase().startsWith('mulai ')) {
        final String rest = text.substring(6).trim();
        text = 'Mulai Rp $rest';
      } else {
        text = 'Rp $text';
      }
    }

    return text;
  }

  String get formattedPrice => formatRupiah(priceDisplay, fallback: priceMyr);

  /// Nilai harga tanpa teks 'Rp' / 'IDR' untuk keperluan tampilan dengan badge/icon Rp terpisah
  String get displayPriceWithoutRp {
    final String full = formattedPrice;
    final String clean = full
        .replaceAll(RegExp(r'\b(rp\.?|idr)\s*', caseSensitive: false), '')
        .trim();
    return clean.isNotEmpty ? clean : full;
  }

  /// Mengecek apakah harga mengandung nilai angka sehingga bisa disematkan badge Rp
  bool get hasNumericPrice => RegExp(r'\d').hasMatch(formattedPrice);

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
