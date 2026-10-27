import 'bootstrap.dart';

/// Default entry point.
///
/// Flavours (staging, Firebase-backed, screenshot mode) get their own
/// `main_*.dart` that calls [bootstrap] with a different [AppConfig].
void main() => bootstrap();
