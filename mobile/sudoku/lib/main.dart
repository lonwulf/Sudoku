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
  // throw StateError('This is test exception');

  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Env loaded: ${dotenv.env}");
  } catch (e) {
    // await dotenv.load(fileName: "mobile/.env");
    debugPrint("❌ Failed to load .env: $e");
    throw StateError('This is test exception');
  }
  // debugPrint("🚀 Starting app without Sentry");
  // runApp(const SudokuApp());
  runZonedGuarded(
    () {
      return SentryFlutter.init((options) {
        options.dsn = dotenv.env['SENTRY_DSN'];
        options.tracesSampleRate = 1.0;
      }, appRunner: () => runApp(const SudokuApp()));
    },
    (error, stacktrace) {
      LoggerService.logError(error, stackTrace: stacktrace);
      throw StateError('This is test exception');
    },
  );
}
