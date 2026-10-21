import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/core/network/auth_interceptor.dart';
import 'package:sudoku/src/modules/auth/data/auth_service.dart';
import 'package:sudoku/src/modules/auth/domain/model/auth_user.dart';
import 'package:sudoku/src/modules/auth/presentation/bloc/auth_cubit.dart';

import 'fixtures.dart';

String _idToken(Map<String, Object> claims) {
  String part(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part(claims)}.sig';
}

final _playerIdToken = _idToken({'sub': 'sub-1', 'name': 'Test Player'});

/// Answers sign-in and refresh with scripted responses.
class _FakeAppAuth implements FlutterAppAuth {
  final tokenRequests = <TokenRequest>[];
  Future<TokenResponse> Function(TokenRequest request)? onToken;
  Object? signInError;

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    final error = signInError;
    if (error != null) throw error;
    return AuthorizationTokenResponse(
      'access-1',
      'refresh-1',
      DateTime.now().add(const Duration(minutes: 5)),
      _playerIdToken,
      'Bearer',
      null,
      null,
      null,
    );
  }

  @override
  Future<TokenResponse> token(TokenRequest request) {
    tokenRequests.add(request);
    return onToken!(request);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TokenResponse _refreshed(String access, {String? refresh}) => TokenResponse(
  access,
  refresh,
  DateTime.now().add(const Duration(minutes: 5)),
  null,
  'Bearer',
  null,
  null,
);

FlutterAppAuthPlatformException _oauthError(String error) =>
    FlutterAppAuthPlatformException(
      code: 'token_failed',
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(error: error),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAppAuth appAuth;
  const storage = FlutterSecureStorage();

  AppAuthService service() =>
      AppAuthService(appAuth: appAuth, storage: storage);

  setUp(() {
    appAuth = _FakeAppAuth();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AuthUser', () {
    test('names the player from the ID token claims', () {
      expect(AuthUser.fromIdToken(_playerIdToken).name, 'Test Player');
      expect(
        AuthUser.fromIdToken(
          _idToken({'sub': 's', 'preferred_username': 'player'}),
        ).name,
        'player',
      );
      expect(AuthUser.fromIdToken(_idToken({'sub': 's'})).name, 'Player');
    });
  });

  group('AppAuthService', () {
    test('signs in, then serves the access token without refreshing', () async {
      final auth = service();

      final user = await auth.signIn();

      expect(user, const AuthUser(id: 'sub-1', name: 'Test Player'));
      expect(await auth.accessToken(), 'access-1');
      expect(appAuth.tokenRequests, isEmpty);
    });

    test('a closed login page signs nobody in', () async {
      appAuth.signInError = FlutterAppAuthUserCancelledException(
        code: 'cancelled',
        platformErrorDetails: FlutterAppAuthPlatformErrorDetails(),
      );
      final auth = service();

      expect(await auth.signIn(), isNull);
      expect(auth.currentUser, isNull);
    });

    test('restores a saved session and refreshes once on first use', () async {
      await service().signIn();
      appAuth.onToken = (_) async => _refreshed('access-2', refresh: 'r-2');
      final restarted = service();

      expect(await restarted.restore(), isNotNull);
      final tokens = await Future.wait([
        restarted.accessToken(),
        restarted.accessToken(),
      ]);

      expect(tokens, ['access-2', 'access-2']);
      expect(appAuth.tokenRequests, hasLength(1));
      expect(appAuth.tokenRequests.single.refreshToken, 'refresh-1');
      expect(await storage.read(key: 'auth.refreshToken'), 'r-2');
    });

    test('a refused refresh signs the player out', () async {
      await service().signIn();
      appAuth.onToken = (_) async =>
          throw _oauthError(FlutterAppAuthOAuthError.invalidGrant);
      final restarted = service();
      await restarted.restore();
      final changes = <AuthUser?>[];
      restarted.userChanges.listen(changes.add);

      expect(await restarted.accessToken(), isNull);
      await pumpEventQueue();

      expect(restarted.currentUser, isNull);
      expect(changes, [null]);
      expect(await storage.read(key: 'auth.refreshToken'), isNull);
    });

    test('a refresh that fails for other reasons keeps the session', () async {
      await service().signIn();
      appAuth.onToken = (_) async =>
          throw PlatformException(code: 'network_error');
      final restarted = service();
      await restarted.restore();

      await expectLater(
        restarted.accessToken(),
        throwsA(isA<PlatformException>()),
      );
      expect(restarted.currentUser, isNotNull);
    });

    test('signing out forgets the session', () async {
      final auth = AppAuthService(
        appAuth: appAuth,
        storage: storage,
        // revocation is best effort; make it fail fast
        http: Dio()..httpClientAdapter = _FailingAdapter(),
      );
      await auth.signIn();

      await auth.signOut();

      expect(auth.currentUser, isNull);
      expect(await auth.accessToken(), isNull);
      expect(await auth.restore(), isNull);
    });
  });

  group('AuthInterceptor', () {
    Future<RequestOptions> send(Future<String?> Function() token) async {
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://api'))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthInterceptor(token));
      await dio.get<void>('/puzzle');
      return adapter.requests.single;
    }

    test('adds the bearer token when signed in', () async {
      final request = await send(() async => 'abc');
      expect(request.headers['Authorization'], 'Bearer abc');
    });

    test('sends no token when signed out', () async {
      final request = await send(() async => null);
      expect(request.headers.containsKey('Authorization'), isFalse);
    });

    test('fails the request when the token cannot be refreshed', () async {
      await expectLater(
        send(() async => throw PlatformException(code: 'network_error')),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
    });
  });

  group('AuthCubit', () {
    test('follows sign-in and sign-out', () async {
      final cubit = AuthCubit(FakeAuthService(signInAs: testUser));

      expect(await cubit.signIn(), isNull);
      expect(cubit.state.user, testUser);

      await cubit.signOut();
      expect(cubit.state.signedIn, isFalse);
      await cubit.close();
    });

    test('reports a failed sign-in', () async {
      final cubit = AuthCubit(_ThrowingAuthService());

      expect(await cubit.signIn(), AuthCubit.signInFailedMessage);
      expect(cubit.state, const AuthState());
      await cubit.close();
    });
  });
}

class _ThrowingAuthService extends FakeAuthService {
  @override
  Future<AuthUser?> signIn() async => throw Exception('discovery failed');
}

class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw const _OfflineError();

  @override
  void close({bool force = false}) {}
}

class _OfflineError implements Exception {
  const _OfflineError();
}
