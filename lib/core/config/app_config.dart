/// Which backend implementation the repositories are bound to.
enum Backend {
  /// Fully offline, seeded demo backend. Zero configuration, works everywhere.
  demo,

  /// Firebase Auth + Cloud Firestore + Storage + Functions + Messaging.
  /// Requires `flutterfire configure` and the Firebase deps in pubspec.yaml.
  firebase,
}

/// Compile-time-ish application configuration.
///
/// Kept as a plain object (rather than scattered `const` globals) so tests and
/// flavours can override it before [ServiceLocator.init] runs.
class AppConfig {
  const AppConfig({
    this.backend = Backend.demo,
    this.appName = 'MSDevBuild Eats',
    this.tagline = 'Everyday everything, delivered',
    this.publisher = 'MSDevBuild',
    this.articleUrl = 'https://blog.msdevbuild.com/',
    this.currencySymbol = 'RM',
    this.currencyLocale = 'ms_MY',
    this.simulatedLatency = const Duration(milliseconds: 450),
    this.orderStageDuration = const Duration(seconds: 8),
    this.enableAnalytics = false,
  });

  final Backend backend;
  final String appName;
  final String tagline;

  /// Who built the demo. Shown on the splash screen and in the about dialog.
  final String publisher;

  /// The article this project accompanies. Surfaced in-app so anyone exploring
  /// the build can find the write-up that explains it.
  final String articleUrl;

  /// Malaysian Ringgit, matching the Grab-in-Malaysia framing of the demo.
  final String currencySymbol;
  final String currencyLocale;

  /// Artificial delay applied by the demo backend so loading/shimmer states are
  /// actually observable. Set to [Duration.zero] in tests.
  final Duration simulatedLatency;

  /// How long each order-tracking stage lasts in the demo simulation.
  final Duration orderStageDuration;

  final bool enableAnalytics;

  /// `MSDevBuild Eats by MSDevBuild` reads badly; this is the byline form.
  String get byline => 'A demo by $publisher';

  static AppConfig instance = const AppConfig();

  static void override(AppConfig config) => instance = config;
}
