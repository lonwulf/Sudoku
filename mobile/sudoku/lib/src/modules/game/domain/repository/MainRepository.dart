import 'package:sudoku/src/core/util/APIResult.dart';
import 'package:sudoku/src/modules/game/domain/model/SudokuGameModel.dart';

abstract class MainRepository {
  Future<APIResult<SudokuGameModel>> fetchChallenge();
}
