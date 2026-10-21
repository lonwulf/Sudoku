import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/di/constant.dart';
import 'package:sudoku/src/modules/auth/presentation/bloc/auth_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_leaderboard_use_case.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_my_score_use_case.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/bloc/leaderboard_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/bloc/my_score_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/screens/my_score_screen.dart';

// Pushed routes sit outside MainScreen's providers, so the app's AuthCubit
// is handed over explicitly; each screen gets a fresh cubit of its own.

Future<void> openMyScore(BuildContext context) {
  final auth = context.read<AuthCubit>();
  return Navigator.of(context).push(
    platformPageRoute(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider(
            create: (_) => MyScoreCubit(getIt<GetMyScoreUseCase>())..load(),
          ),
        ],
        child: const MyScoreScreen(),
      ),
    ),
  );
}

Future<void> openLeaderboard(BuildContext context) {
  final auth = context.read<AuthCubit>();
  return Navigator.of(context).push(
    platformPageRoute(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider(
            create: (_) =>
                LeaderboardCubit(getIt<GetLeaderboardUseCase>())..load(),
          ),
        ],
        child: const LeaderboardScreen(),
      ),
    ),
  );
}
