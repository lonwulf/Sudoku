import 'package:flutter/cupertino.dart';

class LoggerService{
  static void logError(dynamic error, {StackTrace? stackTrace}){
    if(stackTrace != null){
      debugPrint("Error: $error\nSTACK: $stackTrace");
    } else{
      debugPrint("Error: $error");
    }
    //todo send to sentry
  }
}