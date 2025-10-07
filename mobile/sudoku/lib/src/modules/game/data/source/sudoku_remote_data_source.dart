import 'package:sudoku/src/core/network/remote_data_source.dart';
import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/modules/game/data/response/sudoku_game_dto.dart';
import 'package:sudoku/src/modules/game/data/source/game_api_service.dart';

class SudokuRemoteDataSource extends RemoteDataSource {
  final GameAPIService apiService;

  SudokuRemoteDataSource(this.apiService);

  Future<APIResult<SudokuGameDTO>> fetchChallenge(){
    return safeApiCall(() {
      return apiService.getSudokuChallenge();
    });
  }
}
