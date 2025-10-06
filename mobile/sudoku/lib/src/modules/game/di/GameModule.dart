import 'package:dio/dio.dart';
import 'package:sudoku/src/di/Constant.dart';
import 'package:sudoku/src/modules/game/data/repository/MainRepositoryImpl.dart';
import 'package:sudoku/src/modules/game/data/source/GameAPIService.dart';
import 'package:sudoku/src/modules/game/data/source/SudokuRemoteDataSource.dart';
import 'package:sudoku/src/modules/game/domain/repository/MainRepository.dart';
import 'package:sudoku/src/modules/game/domain/usecase/MainUseCase.dart';

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
