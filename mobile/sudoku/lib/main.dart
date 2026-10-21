import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sudoku/src/app/startup_error_app.dart';
import 'package:sudoku/src/app/sudoku_app.dart';
import 'package:sudoku/src/config/app_config.dart';
import 'package:sudoku/src/di/core_module.dart';
import 'package:sudoku/src/modules/auth/di/auth_module.dart';
import 'package:sudoku/src/modules/game/di/game_module.dart';
import 'package:sudoku/src/modules/reminder/di/reminder_module.dart';

// Sentry initialises the Flutter binding and installs the framework and
// platform error handlers, so it starts first and wraps the rest of startup.
Future<void> main() async {
  await SentryFlutter.init((options) {
    options.dsn = AppConfig.sentryDsn;
    options.environment = AppConfig.environment;
    options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
  }, appRunner: _startApp);
}

Future<void> _startApp() async {
  try {
    AppConfig.validate();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setupNetworkDependencies();
    setupAuthModuleDependencies();
    setupGameModuleDependencies();
    setupReminderModuleDependencies();
  } catch (error, stackTrace) {
    // Without this, a startup failure never reaches runApp and leaves a
    // black screen.
    debugPrint('Startup failed: $error\n$stackTrace');
    await Sentry.captureException(error, stackTrace: stackTrace);
    runApp(StartupErrorApp(error: error));
    return;
  }
  runApp(const SudokuApp());
}
