import 'package:equatable/equatable.dart';

import 'address.dart';

class Restaurant extends Equatable {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisines,
    required this.emoji,
    required this.rating,
    required this.reviewCount,
    required this.deliveryFeeMyr,
    required this.minOrderMyr,
    required this.etaMinMinutes,
    required this.etaMaxMinutes,
    required this.distanceKm,
    required this.address,
    this.imageUrl,
    this.coverImageUrl,
    this.description = '',
    this.isOpen = true,
    this.isPromoted = false,
    this.promoText,
    this.priceLevel = 2,
    this.tags = const <String>[],
    this.openingTime = '10:00',
    this.closingTime = '22:00',
    this.ownerId,
    this.phone,
  });

  final String id;
  final String name;
  final List<String> cuisines;
  final String emoji;
  final double rating;
  final int reviewCount;
  final double deliveryFeeMyr;
  final double minOrderMyr;
  final int etaMinMinutes;
  final int etaMaxMinutes;
  final double distanceKm;
  final Address address;
  final String? imageUrl;
  final String? coverImageUrl;
  final String description;
  final bool isOpen;

  /// Surfaced in the "Promoted" rail on the home screen.
  final bool isPromoted;

  /// e.g. `30% off, up to RM 12`.
  final String? promoText;

  /// 1-4, rendered as `RM`..`RMRMRMRM`.
  final int priceLevel;
  final List<String> tags;
  final String openingTime;
  final String closingTime;

  /// Owning [User] id when the restaurant is operated by a partner account.
  final String? ownerId;
  final String? phone;

  bool get hasFreeDelivery => deliveryFeeMyr == 0;

  String get cuisineLabel => cuisines.join(' • ');

  String get priceLevelLabel => 'RM' * priceLevel.clamp(1, 4);

  Restaurant copyWith({
    String? name,
    bool? isOpen,
    double? rating,
    int? reviewCount,
    String? description,
    List<String>? cuisines,
    String? promoText,
  }) {
    return Restaurant(
      id: id,
      name: name ?? this.name,
      cuisines: cuisines ?? this.cuisines,
      emoji: emoji,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      deliveryFeeMyr: deliveryFeeMyr,
      minOrderMyr: minOrderMyr,
      etaMinMinutes: etaMinMinutes,
      etaMaxMinutes: etaMaxMinutes,
      distanceKm: distanceKm,
      address: address,
      imageUrl: imageUrl,
      coverImageUrl: coverImageUrl,
      description: description ?? this.description,
      isOpen: isOpen ?? this.isOpen,
      isPromoted: isPromoted,
      promoText: promoText ?? this.promoText,
      priceLevel: priceLevel,
      tags: tags,
      openingTime: openingTime,
      closingTime: closingTime,
      ownerId: ownerId,
      phone: phone,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        cuisines,
        rating,
        reviewCount,
        deliveryFeeMyr,
        minOrderMyr,
        etaMinMinutes,
        etaMaxMinutes,
        distanceKm,
        isOpen,
        isPromoted,
        promoText,
      ];
}
