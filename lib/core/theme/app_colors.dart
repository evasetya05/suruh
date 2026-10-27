import 'package:flutter/material.dart';

/// Grab-inspired palette.
///
/// The super-app look is built on a single saturated green used for brand
/// surfaces and calls-to-action, a near-black for text, and a very light grey
/// canvas that lets white cards float.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF00B14F);
  static const Color primaryDark = Color(0xFF008C3E);
  static const Color primaryLight = Color(0xFF4CD787);
  static const Color primarySurface = Color(0xFFE6F7EE);

  // Accents used by service tiles / promo chips
  static const Color accentOrange = Color(0xFFFF7A00);
  static const Color accentAmber = Color(0xFFFFB800);
  static const Color accentBlue = Color(0xFF0F73EE);
  static const Color accentPurple = Color(0xFF7B61FF);
  static const Color accentPink = Color(0xFFFF4D80);
  static const Color accentTeal = Color(0xFF00BFA6);

  // Semantic
  static const Color success = Color(0xFF00B14F);
  static const Color warning = Color(0xFFFFB800);
  static const Color danger = Color(0xFFE23744);
  static const Color info = Color(0xFF0F73EE);

  // Light neutrals
  static const Color lightCanvas = Color(0xFFF4F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFFAFAFB);
  static const Color lightBorder = Color(0xFFE7E9EE);
  static const Color lightTextPrimary = Color(0xFF13161C);
  static const Color lightTextSecondary = Color(0xFF5B6472);
  static const Color lightTextTertiary = Color(0xFF98A0AE);

  // Dark neutrals
  static const Color darkCanvas = Color(0xFF0B0F14);
  static const Color darkSurface = Color(0xFF151A21);
  static const Color darkSurfaceAlt = Color(0xFF1D242D);
  static const Color darkBorder = Color(0xFF2A323D);
  static const Color darkTextPrimary = Color(0xFFF2F4F7);
  static const Color darkTextSecondary = Color(0xFFA4AEBC);
  static const Color darkTextTertiary = Color(0xFF6C7686);

  /// Deterministic tint for a category/cuisine chip so the home grid looks
  /// designed rather than random on every rebuild.
  static const List<Color> categoryTints = <Color>[
    accentOrange,
    accentBlue,
    accentPurple,
    accentPink,
    accentTeal,
    accentAmber,
  ];

  static Color tintFor(String seed) =>
      categoryTints[seed.hashCode.abs() % categoryTints.length];
}
