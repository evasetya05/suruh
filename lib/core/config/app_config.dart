/// Which backend implementation the repositories are bound to.
enum Backend {
  /// SURUH Django REST Framework API (https://suruhjak.teknusa.com)
  suruhApi,

  /// Firebase Auth + Cloud Firestore + Storage + Functions + Messaging.
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
    this.articleUrl = 'https://suruhjak.teknusa.com/api/docs/',
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

  /// Explicit API Base URL override (e.g. "https://suruhjak.teknusa.com").
  final String? customApiBaseUrl;

  /// Returns the effective API Base URL pointing to the SURUH production backend.
  String get apiBaseUrl {
    if (customApiBaseUrl != null && customApiBaseUrl!.trim().isNotEmpty) {
      return customApiBaseUrl!.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://suruhjak.teknusa.com';
  }

  final Duration simulatedLatency;
  final Duration orderStageDuration;
  final bool enableAnalytics;

  String get byline => '$appName - $publisher';

  static AppConfig instance = const AppConfig();

  static void override(AppConfig config) => instance = config;
}
