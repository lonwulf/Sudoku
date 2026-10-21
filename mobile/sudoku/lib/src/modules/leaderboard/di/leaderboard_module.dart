import 'package:dio/dio.dart';
import 'package:sudoku/src/di/constant.dart';
import 'package:sudoku/src/modules/leaderboard/data/repository/leaderboard_repository_impl.dart';
import 'package:sudoku/src/modules/leaderboard/data/source/leaderboard_api_service.dart';
import 'package:sudoku/src/modules/leaderboard/data/source/leaderboard_remote_data_source.dart';
import 'package:sudoku/src/modules/leaderboard/domain/repository/leaderboard_repository.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_leaderboard_use_case.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_my_score_use_case.dart';

void setupLeaderboardModuleDependencies() {
  getIt.registerLazySingleton<LeaderboardAPIService>(
    () => LeaderboardAPIServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<LeaderboardRemoteDataSource>(
    () => LeaderboardRemoteDataSource(getIt<LeaderboardAPIService>()),
  );

  getIt.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(getIt<LeaderboardRemoteDataSource>()),
  );

  getIt.registerFactory(
    () => GetLeaderboardUseCase(getIt<LeaderboardRepository>()),
  );
  getIt.registerFactory(
    () => GetMyScoreUseCase(getIt<LeaderboardRepository>()),
  );
}
