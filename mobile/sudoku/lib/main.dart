import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sudoku/src/app/sudoku_app.dart';
import 'package:sudoku/src/config/app_config.dart';
import 'package:sudoku/src/core/util/logger_service.dart';
import 'package:sudoku/src/di/core_module.dart';
import 'package:sudoku/src/modules/game/di/game_module.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  AppConfig.validate();
  await setupNetworkDependencies();
  await setupGameModuleDependencies();
  // debugPrint("🚀 Starting app without Sentry");
  // runApp(const SudokuApp());
  runZonedGuarded(
    () {
      return SentryFlutter.init((options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 1.0;
      }, appRunner: () => runApp(const SudokuApp()));
    },
    (error, stacktrace) {
      LoggerService.logError(error, stackTrace: stacktrace);
      throw StateError('This is test exception');
    },
  );
}
