import 'package:sudoku/src/modules/game/data/response/SudokuGameDTO.dart';
import 'package:sudoku/src/modules/game/domain/model/SudokuGameModel.dart';

extension SudokuPuzzleMapper on SudokuGameDTO {
  SudokuGameModel toDomainModel() {
    return SudokuGameModel(
      id: id ?? '',
      difficulty: difficulty ?? "Medium",
      puzzle: puzzle ?? List.generate(9, (_) => List.filled(9, 0)),
      solution: solution ?? List.generate(9, (_) => List.filled(9, 0)),
    );
  }
}
