import '../../domain/entities/promo.dart';

class PromoModel extends Promo {
  const PromoModel({
    required super.id,
    required super.code,
    required super.title,
    required super.subtitle,
    required super.discountPercent,
    required super.maxDiscountMyr,
    super.minSpendMyr,
    super.emoji,
    super.badge,
    super.expiresAt,
  });

  factory PromoModel.fromEntity(Promo p) => PromoModel(
        id: p.id,
        code: p.code,
        title: p.title,
        subtitle: p.subtitle,
        discountPercent: p.discountPercent,
        maxDiscountMyr: p.maxDiscountMyr,
        minSpendMyr: p.minSpendMyr,
        emoji: p.emoji,
        badge: p.badge,
        expiresAt: p.expiresAt,
      );

  factory PromoModel.fromJson(Map<String, dynamic> json) => PromoModel(
        id: json['id'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        discountPercent: json['discountPercent'] as int,
        maxDiscountMyr: (json['maxDiscountMyr'] as num).toDouble(),
        minSpendMyr: (json['minSpendMyr'] as num?)?.toDouble() ?? 0,
        emoji: json['emoji'] as String? ?? '🎉',
        badge: json['badge'] as String?,
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'code': code,
        'title': title,
        'subtitle': subtitle,
        'discountPercent': discountPercent,
        'maxDiscountMyr': maxDiscountMyr,
        'minSpendMyr': minSpendMyr,
        'emoji': emoji,
        'badge': badge,
        'expiresAt': expiresAt?.toIso8601String(),
      };
}
