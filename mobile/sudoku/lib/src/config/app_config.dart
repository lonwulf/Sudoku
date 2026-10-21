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

  /// Keycloak realm URL. Must be the exact issuer the backend trusts.
  static const oidcIssuer = String.fromEnvironment('OIDC_ISSUER');
  static const oidcClientId = String.fromEnvironment(
    'OIDC_CLIENT_ID',
    defaultValue: 'sudoku-mobile',
  );

  /// Registered with Keycloak; its scheme is also declared in the Android
  /// build (appAuthRedirectScheme) and the iOS Info.plist.
  static const oidcRedirectUrl = 'com.lonwulf.labs.sudoku:/oauthredirect';

  static void validate() {
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is not set. Run with '
        '--dart-define-from-file=config/debug.json (see config/example.json).',
      );
    }
    if (oidcIssuer.isEmpty) {
      throw StateError(
        'OIDC_ISSUER is not set. Add it to config/debug.json '
        '(see config/example.json).',
      );
    }
    if (kReleaseMode &&
        !(apiBaseUrl.startsWith('https://') &&
            oidcIssuer.startsWith('https://'))) {
      throw StateError(
        'Release builds must use https for API_BASE_URL and OIDC_ISSUER.',
      );
    }
  }
}
