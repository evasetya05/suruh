import 'package:equatable/equatable.dart';

/// A promotion banner / voucher code.
class Promo extends Equatable {
  const Promo({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.discountPercent,
    required this.maxDiscountMyr,
    this.minSpendMyr = 0,
    this.emoji = '🎉',
    this.badge,
    this.expiresAt,
  });

  final String id;
  final String code;
  final String title;
  final String subtitle;

  /// 0-100.
  final int discountPercent;
  final double maxDiscountMyr;
  final double minSpendMyr;
  final String emoji;

  /// e.g. `NEW USER`.
  final String? badge;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool isEligibleFor(double subtotal) => !isExpired && subtotal >= minSpendMyr;

  /// Discount applied to [subtotal], respecting the cap and minimum spend.
  double discountFor(double subtotal) {
    if (!isEligibleFor(subtotal)) return 0;
    final double raw = subtotal * discountPercent / 100;
    return raw > maxDiscountMyr ? maxDiscountMyr : raw;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        code,
        title,
        discountPercent,
        maxDiscountMyr,
        minSpendMyr,
      ];
}
