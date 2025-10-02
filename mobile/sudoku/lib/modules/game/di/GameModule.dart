import 'package:sudoku/di/Constant.dart';

class GameModule{
  void setupGameModule(){
    getIt.registerSingleton<SudokuRemoteDataSource>(
        SudokuRemoteDataSource(getIt<GameAPIService>())
    );
  }
}