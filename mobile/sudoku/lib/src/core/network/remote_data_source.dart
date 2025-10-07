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
            httpResult: HttpResult.SERVER_ERROR,
          );
        } else {
          return APIResult.error(
            code: statusCode,
            msg: ex.message,
            httpResult: HttpResult.UN_DEFINED,
          );
        }
      }
      return APIResult.error(
        msg: ex.message,
        httpResult: HttpResult.UN_DEFINED,
      );
    } on TimeoutException {
      return APIResult.error(
        msg: HttpResult.TIMEOUT.name,
        httpResult: HttpResult.TIMEOUT,
      );
    } catch (e) {
      return APIResult.error(
        msg: e.toString(),
        httpResult: HttpResult.UN_DEFINED,
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
        httpResult: HttpResult.CLIENT_ERROR,
      );
    } catch (e) {
      return APIResult.error(
        code: ex.response?.statusCode,
        msg: e.toString(),
        httpResult: HttpResult.CLIENT_ERROR,
      );
    }
  }
}
