import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';

abstract class MainRepository {
  Future<APIResult<SudokuGameModel>> fetchChallenge();
}
