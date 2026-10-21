import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sudoku/src/config/app_config.dart';
import 'package:sudoku/src/core/network/auth_interceptor.dart';
import 'package:sudoku/src/core/util/network_monitor.dart';
import 'package:sudoku/src/modules/auth/data/auth_service.dart';

import 'constant.dart';

void setupNetworkDependencies() {
  getIt.registerLazySingleton<NetworkMonitor>(() => NetworkMonitor());
  getIt.registerLazySingleton<Dio>(() => provideDioClient());
}

Dio provideDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(() => getIt<AuthService>().accessToken()),
  );
  // Logging full bodies costs UI-thread time and leaks data to logcat.
  if (kDebugMode) {
    dio.interceptors.add(provideLoggingInterceptor());
  }
  return dio;
}

PrettyDioLogger provideLoggingInterceptor() {
  return PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseBody: true,
    responseHeader: false,
    error: true,
    compact: true,
    maxWidth: 90,
  );
}
