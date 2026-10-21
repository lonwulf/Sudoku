import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sudoku/src/theme/app_theme.dart';

/// Shown instead of the app when startup fails, e.g. when the build was run
/// without `--dart-define-from-file=config/debug.json`.
class StartupErrorApp extends StatelessWidget {
  final Object error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final message = kReleaseMode
        ? 'Something went wrong while starting the app.'
        : error is StateError
        ? (error as StateError).message
        : '$error';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildMaterialTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GameColors.errorText,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
