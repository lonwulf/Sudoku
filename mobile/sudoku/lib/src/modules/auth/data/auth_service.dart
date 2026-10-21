import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sudoku/src/config/app_config.dart';
import 'package:sudoku/src/modules/auth/domain/model/auth_user.dart';

abstract class AuthService {
  AuthUser? get currentUser;

  /// Emits whenever the player signs in or out, including when an expired
  /// session is dropped.
  Stream<AuthUser?> get userChanges;

  /// Loads a session saved by an earlier run, without touching the network.
  Future<AuthUser?> restore();

  /// Opens the Keycloak login page. Returns null if the player closes it.
  Future<AuthUser?> signIn();

  Future<void> signOut();

  /// A current access token, refreshed when about to expire. Null when
  /// signed out or the session can no longer be refreshed.
  Future<String?> accessToken();
}

/// Keycloak sign-in with the authorization code flow and PKCE (AppAuth).
/// The refresh token is an offline token, so players stay signed in across
/// restarts; it lives in the platform keystore/keychain.
class AppAuthService implements AuthService {
  static const _scopes = ['openid', 'profile', 'email', 'offline_access'];
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _idTokenKey = 'auth.idToken';

  /// Refresh this long before expiry so a token can't lapse in flight.
  static const _expiryMargin = Duration(seconds: 30);

  final FlutterAppAuth appAuth;
  final FlutterSecureStorage storage;

  /// Plain client for token revocation; not the API client.
  final Dio http;

  // Access tokens last minutes, so they are kept in memory only.
  String? _accessToken;
  DateTime? _expiresAt;
  Future<String?>? _refreshing;
  AuthUser? _user;
  final _changes = StreamController<AuthUser?>.broadcast();

  AppAuthService({
    FlutterAppAuth? appAuth,
    FlutterSecureStorage? storage,
    Dio? http,
  }) : appAuth = appAuth ?? const FlutterAppAuth(),
       storage = storage ?? const FlutterSecureStorage(),
       http = http ?? Dio();

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get userChanges => _changes.stream;

  @override
  Future<AuthUser?> restore() async {
    final idToken = await storage.read(key: _idTokenKey);
    final refreshToken = await storage.read(key: _refreshTokenKey);
    if (idToken == null || refreshToken == null) return null;
    _setUser(AuthUser.fromIdToken(idToken));
    return _user;
  }

  @override
  Future<AuthUser?> signIn() async {
    try {
      final response = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AppConfig.oidcClientId,
          AppConfig.oidcRedirectUrl,
          issuer: AppConfig.oidcIssuer,
          scopes: _scopes,
          // Always ask for credentials, so signing out then in can switch
          // players even if the browser still holds a Keycloak session.
          promptValues: const ['login'],
          // The dev Keycloak is plain http; release builds require https.
          allowInsecureConnections: !kReleaseMode,
          externalUserAgent:
              ExternalUserAgent.ephemeralAsWebAuthenticationSession,
        ),
      );
      await _save(response);
      return _user;
    } on FlutterAppAuthUserCancelledException {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    final refreshToken = await storage.read(key: _refreshTokenKey);
    await _clear();
    if (refreshToken != null) unawaited(_revoke(refreshToken));
  }

  @override
  Future<String?> accessToken() {
    if (_user == null) return Future.value();
    final token = _accessToken, expiresAt = _expiresAt;
    if (token != null &&
        expiresAt != null &&
        DateTime.now().isBefore(expiresAt.subtract(_expiryMargin))) {
      return Future.value(token);
    }
    // Concurrent requests share one refresh.
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final refreshToken = await storage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      await _clear();
      return null;
    }
    try {
      final response = await appAuth.token(
        TokenRequest(
          AppConfig.oidcClientId,
          AppConfig.oidcRedirectUrl,
          issuer: AppConfig.oidcIssuer,
          refreshToken: refreshToken,
          scopes: _scopes,
          allowInsecureConnections: !kReleaseMode,
        ),
      );
      await _save(response);
      return _accessToken;
    } on FlutterAppAuthPlatformException catch (e) {
      // Expired or revoked session: sign out. Anything else (e.g. offline)
      // is passed on so the request fails rather than going out anonymous.
      if (e.platformErrorDetails.error ==
          FlutterAppAuthOAuthError.invalidGrant) {
        await _clear();
        return null;
      }
      rethrow;
    }
  }

  Future<void> _save(TokenResponse response) async {
    _accessToken = response.accessToken;
    _expiresAt = response.accessTokenExpirationDateTime;
    final refreshToken = response.refreshToken;
    if (refreshToken != null) {
      await storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    final idToken = response.idToken;
    if (idToken != null) {
      await storage.write(key: _idTokenKey, value: idToken);
      _setUser(AuthUser.fromIdToken(idToken));
    }
  }

  Future<void> _clear() async {
    _accessToken = null;
    _expiresAt = null;
    await storage.delete(key: _refreshTokenKey);
    await storage.delete(key: _idTokenKey);
    _setUser(null);
  }

  void _setUser(AuthUser? user) {
    if (user == _user) return;
    _user = user;
    _changes.add(user);
  }

  /// Best effort: the local tokens are already gone, so a failure here only
  /// leaves the offline session to expire on the server.
  Future<void> _revoke(String refreshToken) async {
    try {
      final discovery = await http.get<Map<String, dynamic>>(
        '${AppConfig.oidcIssuer}/.well-known/openid-configuration',
      );
      final endpoint = discovery.data?['revocation_endpoint'] as String?;
      if (endpoint == null) return;
      await http.post<void>(
        endpoint,
        data: {
          'token': refreshToken,
          'token_type_hint': 'refresh_token',
          'client_id': AppConfig.oidcClientId,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } catch (e) {
      debugPrint('Token revocation failed: $e');
    }
  }
}
