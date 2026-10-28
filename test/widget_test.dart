import 'package:flutter_test/flutter_test.dart';
import 'package:suruh/core/config/app_config.dart';

void main() {
  test('AppConfig initializes with SURUH defaults and live backend', () {
    const AppConfig config = AppConfig();
    expect(config.appName, 'SURUH');
    expect(config.apiBaseUrl, 'https://suruhjak.teknusa.com');
    expect(config.backend, Backend.suruhApi);
  });
}
