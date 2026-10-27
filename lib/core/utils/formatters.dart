import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// Presentation-layer formatting helpers.
abstract final class Formatters {
  /// `RM 24.90`
  static String currency(double amount) {
    final NumberFormat format = NumberFormat.currency(
      locale: 'en_US',
      symbol: '${AppConfig.instance.currencySymbol} ',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  /// `RM 24.90` without the space, for tight spaces like chips.
  static String currencyCompact(double amount) =>
      '${AppConfig.instance.currencySymbol}${amount.toStringAsFixed(2)}';

  /// `4.8` - ratings always show one decimal.
  static String rating(double value) => value.toStringAsFixed(1);

  /// `1.2 km` / `850 m`
  static String distance(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  /// `25-35 min`
  static String etaRange(int minMinutes, int maxMinutes) =>
      '$minMinutes-$maxMinutes min';

  /// `2.4k` for review counts.
  static String compactCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final double k = value / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  /// `12 Mar 2026`
  static String date(DateTime value) => DateFormat('d MMM yyyy').format(value);

  /// `12 Mar, 7:45 PM`
  static String dateTime(DateTime value) =>
      DateFormat('d MMM, h:mm a').format(value);

  /// `7:45 PM`
  static String time(DateTime value) => DateFormat('h:mm a').format(value);

  /// `3 days ago`, `Just now`
  static String relative(DateTime value) {
    final Duration diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      final int weeks = diff.inDays ~/ 7;
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    }
    return date(value);
  }

  /// `#O202607310042` - a short, human-quotable reference.
  ///
  /// Ids vary in length (seeded ids are short, generated ones carry a date
  /// stamp), so this takes the last 8 characters rather than assuming a
  /// minimum length.
  static String orderNumber(String orderId) {
    final String cleaned = orderId.toUpperCase().replaceAll('-', '');
    if (cleaned.isEmpty) return '#UNKNOWN';
    return '#${cleaned.length <= 8 ? cleaned : cleaned.substring(cleaned.length - 8)}';
  }

  /// Masks all but the last four digits of a card number.
  static String maskedCard(String last4) => '•••• •••• •••• $last4';
}
