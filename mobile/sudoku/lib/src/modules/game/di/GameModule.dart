import 'package:sudoku/src/di/Constant.dart';
import 'package:sudoku/src/modules/game/data/source/GameAPIService.dart';
import 'package:sudoku/src/modules/game/data/source/SudokuRemoteDataSource.dart';

class GameModule{
  void setupGameModule(){
    getIt.registerSingleton<SudokuRemoteDataSource>(
        SudokuRemoteDataSource(getIt<GameAPIService>())
    );
  }
}