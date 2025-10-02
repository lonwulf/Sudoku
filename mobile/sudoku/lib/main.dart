import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sudoku/src/app/SudokuApp.dart';
import 'package:sudoku/src/core/util/LoggerService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load(fileName: ".env");
  runZonedGuarded(
    () async {
      await SentryFlutter.init((options) {
        options.dsn = dotenv.env['SENTRY_DSN'];
        options.tracesSampleRate = 1.0;
      }, appRunner: () => runApp(const SudokuApp()));
    },
    (error, stacktrace) {
      LoggerService.logError(error, stackTrace: stacktrace);
    },
  );
}
