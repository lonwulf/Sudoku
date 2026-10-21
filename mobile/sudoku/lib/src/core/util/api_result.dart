import 'api_status.dart';

class APIResult<T> {
  final T? result;
  final int? code;
  final String? msg;
  final HttpResult? httpResult;
  final APIStatus? status;

  APIResult._({
    this.result,
    this.code,
    this.msg,
    this.httpResult,
    required this.status,
  });

  factory APIResult.success(T result) =>
      APIResult._(status: APIStatus.success, result: result);

  factory APIResult.loading() => APIResult._(status: APIStatus.loading);

  factory APIResult.error({int? code, String? msg, HttpResult? httpResult}) =>
      APIResult._(
        status: APIStatus.error,
        code: code,
        msg: msg,
        httpResult: httpResult,
      );

  @override
  String toString() {
    switch (status) {
      case APIStatus.loading:
        return 'Loading';
      case APIStatus.success:
        return 'Success [data = $result]';
      case APIStatus.error:
        return 'Error [code = $code, msg = $msg, httpResult = $httpResult]';
      case null:
        return 'null';
    }
  }
}

enum HttpResult {
  slowConnection,
  timeout,
  serverError,
  clientError,
  badResponse,
  undefined,
  notFound,
}
