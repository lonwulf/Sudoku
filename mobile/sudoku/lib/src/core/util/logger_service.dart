import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LoggerService {
  static void logError(dynamic error, {StackTrace? stackTrace}) {
    if (stackTrace != null) {
      debugPrint("Error: $error\nSTACK: $stackTrace");
    } else {
      debugPrint("Error: $error");
    }
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}
