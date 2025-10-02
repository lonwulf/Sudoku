import 'package:sudoku/src/core/network/RemoteDataSource.dart';
import 'package:sudoku/src/core/util/APIResult.dart';
import 'package:sudoku/src/modules/game/data/response/SudokuGameDTO.dart';
import 'package:sudoku/src/modules/game/data/source/GameAPIService.dart';

class SudokuRemoteDataSource extends RemoteDataSource {
  final GameAPIService apiService;

  SudokuRemoteDataSource(this.apiService);

  Future<APIResult<SudokuGameDTO>> fetchChallenge(){
    return safeApiCall(() {
      return apiService.getSudokuChallenge();
    });
  }
}
