import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';

const testPuzzle = [
  [0, 2, 0, 0, 0, 0, 7, 0, 9],
  [4, 0, 0, 7, 0, 9, 0, 2, 3],
  [7, 8, 0, 0, 0, 0, 0, 5, 0],
  [0, 0, 0, 0, 6, 0, 0, 0, 7],
  [3, 0, 5, 8, 9, 0, 0, 1, 0],
  [8, 0, 0, 2, 0, 0, 3, 6, 5],
  [0, 3, 1, 6, 0, 2, 0, 0, 0],
  [0, 0, 2, 9, 0, 0, 0, 3, 0],
  [9, 0, 0, 5, 3, 1, 0, 4, 2],
];

const testSolution = [
  [1, 2, 3, 4, 5, 6, 7, 8, 9],
  [4, 5, 6, 7, 8, 9, 1, 2, 3],
  [7, 8, 9, 1, 2, 3, 4, 5, 6],
  [2, 1, 4, 3, 6, 5, 8, 9, 7],
  [3, 6, 5, 8, 9, 7, 2, 1, 4],
  [8, 9, 7, 2, 1, 4, 3, 6, 5],
  [5, 3, 1, 6, 4, 2, 9, 7, 8],
  [6, 4, 2, 9, 7, 8, 5, 3, 1],
  [9, 7, 8, 5, 3, 1, 6, 4, 2],
];

SudokuGameModel testGame() => SudokuGameModel(
  id: 'test',
  difficulty: 'medium',
  puzzle: [
    for (final row in testPuzzle) [...row],
  ],
  solution: testSolution,
);
