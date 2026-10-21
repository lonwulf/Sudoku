import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The game's palette, shared by the Material and Cupertino themes and the
/// board widgets.
abstract final class GameColors {
  static const background = Color(0xFF2C3E5A);
  static const surface = Color(0xFF1E2940);
  static const onBackground = Color(0xFFFFFFFE);
  static const muted = Color(0xB3FFFFFF);
  static const subtle = Color(0x8AFFFFFF);
  static const accent = Color(0xFF4ECDC4);
  static const onAccent = Color(0xFF10202E);
  static const selected = Color(0xFF4169E1);
  static const highlighted = Color(0xFF4B5B8B);
  static const conflict = Color(0xFF8B4B68);
  static const playerEntry = Color(0xFF9FB4FF);
  static const errorText = Color(0xFFFF8A80);
}

final ColorScheme sharedScheme = ColorScheme.fromSeed(
  seedColor: GameColors.accent,
  brightness: Brightness.dark,
  primary: GameColors.accent,
  onPrimary: GameColors.onAccent,
  surface: GameColors.background,
  onSurface: GameColors.onBackground,
  error: GameColors.errorText,
);

ThemeData buildMaterialTheme() {
  return ThemeData(
    colorScheme: sharedScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: GameColors.background,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14),
      titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: GameColors.background,
      foregroundColor: GameColors.onBackground,
      titleTextStyle: TextStyle(fontSize: 16, color: GameColors.onBackground),
    ),
  );
}

CupertinoThemeData buildCupertinoTheme() {
  return const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: GameColors.accent,
    scaffoldBackgroundColor: GameColors.background,
    barBackgroundColor: GameColors.background,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(fontSize: 14, color: GameColors.onBackground),
      navTitleTextStyle: TextStyle(
        fontSize: 16,
        color: GameColors.onBackground,
      ),
      actionTextStyle: TextStyle(fontSize: 14, color: GameColors.accent),
    ),
  );
}
