import 'package:dio/dio.dart';
import 'package:sudoku/src/di/constant.dart';
import 'package:sudoku/src/modules/game/data/repository/main_repository_impl.dart';
import 'package:sudoku/src/modules/game/data/source/game_api_service.dart';
import 'package:sudoku/src/modules/game/data/source/sudoku_remote_data_source.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';

Future<void> setupGameModuleDependencies() async {
  getIt.registerLazySingleton<GameAPIService>(
    () => GameAPIServiceImpl(getIt<Dio>()),
  );

  getIt.registerSingleton<SudokuRemoteDataSource>(
    SudokuRemoteDataSource(getIt<GameAPIService>()),
  );

  getIt.registerLazySingleton<MainRepository>(
    () => MainRepositoryImpl(getIt<SudokuRemoteDataSource>()),
  );

  getIt.registerFactory(() => MainUseCase(getIt<MainRepository>()));
}
