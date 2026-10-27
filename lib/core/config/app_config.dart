import 'package:flutter/foundation.dart';

/// Which backend implementation the repositories are bound to.
enum Backend {
  /// SURUH Django REST Framework API (suruh_backend/compose.yaml on port 8019)
  suruhApi,

  /// Fully offline, seeded demo backend. Zero configuration, works everywhere.
  demo,

  /// Firebase Auth + Cloud Firestore + Storage + Functions + Messaging.
  /// Requires `flutterfire configure` and the Firebase deps in pubspec.yaml.
  firebase,
}

/// Application configuration.
///
/// Configures backend target, API host, branding, currency, and operational params.
class AppConfig {
  const AppConfig({
    this.backend = Backend.suruhApi,
    this.appName = 'SURUH',
    this.tagline = 'Ada urusan? Suruh kami',
    this.publisher = 'SURUH Pontianak',
    this.articleUrl = 'http://localhost:8019/api/docs/',
    this.currencySymbol = 'Rp',
    this.currencyLocale = 'id_ID',
    this.customApiBaseUrl,
    this.simulatedLatency = const Duration(milliseconds: 300),
    this.orderStageDuration = const Duration(seconds: 8),
    this.enableAnalytics = false,
  });

  final Backend backend;
  final String appName;
  final String tagline;

  /// Who built or operates the platform.
  final String publisher;

  /// API documentation / Swagger URL.
  final String articleUrl;

  /// Indonesian Rupiah currency formatting.
  final String currencySymbol;
  final String currencyLocale;

  /// Explicit API Base URL override (e.g. "http://192.168.1.100:8019").
  final String? customApiBaseUrl;

  /// Returns the effective API Base URL pointing to suruh_backend.
  /// Matches compose.yaml port 8019:8000.
  String get apiBaseUrl {
    if (customApiBaseUrl != null && customApiBaseUrl!.trim().isNotEmpty) {
      return customApiBaseUrl!.trim().replaceAll(RegExp(r'/+$'), '');
    }
    if (kIsWeb) return 'http://localhost:8019';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8019';
    }
    return 'http://localhost:8019';
  }

  final Duration simulatedLatency;
  final Duration orderStageDuration;
  final bool enableAnalytics;

  String get byline => '$appName - $publisher';

  static AppConfig instance = const AppConfig();

  static void override(AppConfig config) => instance = config;
}
