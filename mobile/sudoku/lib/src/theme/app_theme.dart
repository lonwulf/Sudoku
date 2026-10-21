import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final ColorScheme sharedScheme = ColorScheme.fromSeed(seedColor: Colors.yellow);

ThemeData buildMaterialTheme() {
  return ThemeData(
    colorScheme: sharedScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14),
      titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: sharedScheme.primaryContainer,
      foregroundColor: sharedScheme.onPrimaryContainer,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: sharedScheme.onPrimaryContainer,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: sharedScheme.primaryContainer,
      selectedItemColor: sharedScheme.onPrimaryContainer,
      unselectedItemColor: sharedScheme.onPrimaryContainer.withValues(alpha: 0.7),
      type: BottomNavigationBarType.fixed,
    ),
  );
}

CupertinoThemeData buildCupertinoTheme() {
  return CupertinoThemeData(
    primaryColor: sharedScheme.primary,
    scaffoldBackgroundColor: CupertinoColors.white,
    barBackgroundColor: sharedScheme.primaryContainer,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        fontSize: 14,
        color: sharedScheme.onPrimaryContainer,
      ),
      navTitleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: sharedScheme.onPrimaryContainer,
      ),
      actionTextStyle: TextStyle(
        fontSize: 14,
        color: sharedScheme.onPrimaryContainer,
      ),
    ),
  );
}
