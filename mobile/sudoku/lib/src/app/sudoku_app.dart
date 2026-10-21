import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/core/util/network_monitor.dart';
import 'package:sudoku/src/di/constant.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';
import 'package:sudoku/src/modules/game/presentation/screens/main_screen.dart';

import '../theme/app_theme.dart';

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
          ios: PlatformStyle.Cupertino,
        ),
      ),
      builder: (context) => PlatformApp(
        debugShowCheckedModeBanner: false,
        material: (_, __) => MaterialAppData(theme: buildMaterialTheme()),
        cupertino: (_, __) => CupertinoAppData(theme: buildCupertinoTheme()),
        home: BlocProvider(
          create: (_) =>
              MainBloc(getIt<MainUseCase>(), getIt<NetworkMonitor>()),
          child: const MainScreen(),
        ),
      ),
    );
  }
}
