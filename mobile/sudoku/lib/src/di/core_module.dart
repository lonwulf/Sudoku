import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sudoku/src/config/app_config.dart';

import 'constant.dart';

Future<void> setupNetworkDependencies() async {
  getIt.registerLazySingleton<PrettyDioLogger>(
    () => provideLoggingInterceptor(),
  );
  getIt.registerLazySingleton<Dio>(
    () => provideDioClient(getIt<PrettyDioLogger>()),
  );
}

Dio provideDioClient(PrettyDioLogger logger) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  );
  dio.interceptors.add(logger);
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
