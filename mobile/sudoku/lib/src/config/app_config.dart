import 'package:flutter/foundation.dart';

/// Build-time configuration, supplied with
/// `--dart-define-from-file=config/<debug|release>.json`.
class AppConfig {
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kReleaseMode ? 'release' : 'debug',
  );
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: '/api/v1',
  );
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static void validate() {
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is not set. Run with '
        '--dart-define-from-file=config/debug.json (see config/example.json).',
      );
    }
    if (kReleaseMode && !apiBaseUrl.startsWith('https://')) {
      throw StateError('Release builds must use an https API_BASE_URL.');
    }
  }
}
