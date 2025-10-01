import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/modules/home/presentation/screens/MainScreen.dart';

import '../theme/AppTheme.dart';

void main() {
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformProvider(
      initialPlatform: defaultTargetPlatform == TargetPlatform.android
          ? TargetPlatform.android
          : TargetPlatform.iOS,
      settings: PlatformSettingsData(
        platformStyle: PlatformStyleData(
            android: PlatformStyle.Material,
            ios: PlatformStyle.Cupertino
        ),
      ),
      builder: (context) =>
          PlatformApp(
            debugShowCheckedModeBanner: false,
            material: (_, __) => MaterialAppData(theme: buildMaterialTheme()),
            cupertino: (_, __) =>
                CupertinoAppData(theme: buildCupertinoTheme()),
            home: const MainScreen(),
          ),
    );
  }
}