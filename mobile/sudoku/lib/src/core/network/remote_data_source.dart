import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../util/api_result.dart';

abstract class RemoteDataSource {
  Future<APIResult<T>> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      final result = await apiCall();
      return APIResult.success(result);
    } on DioException catch (ex) {
      final response = ex.response;
      final statusCode = response?.statusCode;

      if (statusCode != null) {
        if (statusCode >= 400 && statusCode <= 451) {
          return parseHttpError(ex);
        } else if (statusCode >= 500 && statusCode <= 599) {
          return APIResult.error(
            code: statusCode,
            msg: ex.message,
            httpResult: HttpResult.serverError,
          );
        } else {
          return APIResult.error(
            code: statusCode,
            msg: ex.message,
            httpResult: HttpResult.undefined,
          );
        }
      }
      return APIResult.error(
        msg: ex.message,
        httpResult: HttpResult.undefined,
      );
    } on TimeoutException {
      return APIResult.error(
        msg: HttpResult.timeout.name,
        httpResult: HttpResult.timeout,
      );
    } catch (e) {
      return APIResult.error(
        msg: e.toString(),
        httpResult: HttpResult.undefined,
      );
    }
  }

  APIResult<Never> parseHttpError(DioException ex) {
    try {
      final errorBody = ex.response?.data;
      final errorMsg = errorBody is String
          ? jsonDecode(errorBody)
          : errorBody as Map<String, dynamic>;
      final msg = errorMsg['message']?.toString() ?? "Unknown error message";
      return APIResult.error(
        code: ex.response?.statusCode,
        msg: msg,
        httpResult: HttpResult.clientError,
      );
    } catch (e) {
      return APIResult.error(
        code: ex.response?.statusCode,
        msg: e.toString(),
        httpResult: HttpResult.clientError,
      );
    }
  }
}
