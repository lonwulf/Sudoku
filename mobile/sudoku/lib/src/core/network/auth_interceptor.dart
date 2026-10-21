import 'package:dio/dio.dart';

/// Adds the player's bearer token to API requests when signed in. Requests
/// go out without one when signed out; the backend decides what needs it.
class AuthInterceptor extends Interceptor {
  final Future<String?> Function() accessToken;

  AuthInterceptor(this.accessToken);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await accessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } catch (e) {
      // A failed refresh (e.g. offline) fails the request like any network
      // error, instead of sending it anonymously.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: e,
          message: 'Could not refresh your sign-in',
        ),
      );
    }
  }
}
