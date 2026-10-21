import 'package:equatable/equatable.dart';

class SudokuGameModel extends Equatable {
  final String id;
  final String difficulty;

  /// The starting grid; non-zero cells are givens and cannot be changed.
  final List<List<int>> puzzle;
  final List<List<int>> solution;

  /// The grid as the player has filled it in.
  final List<List<int>> board;

  SudokuGameModel({
    required this.id,
    required this.difficulty,
    required List<List<int>> puzzle,
    required List<List<int>> solution,
    List<List<int>>? board,
  }) : puzzle = _unmodifiable(puzzle),
       solution = _unmodifiable(solution),
       board = _unmodifiable(board ?? puzzle);

  bool isGiven(int row, int col) => puzzle[row][col] != 0;

  SudokuGameModel withCell(int row, int col, int value) {
    final next = [
      for (final cells in board) [...cells],
    ];
    next[row][col] = value;
    return SudokuGameModel(
      id: id,
      difficulty: difficulty,
      puzzle: puzzle,
      solution: solution,
      board: next,
    );
  }

  static List<List<int>> _unmodifiable(List<List<int>> grid) =>
      List.unmodifiable([for (final row in grid) List<int>.unmodifiable(row)]);

  @override
  List<Object?> get props => [id, difficulty, puzzle, solution, board];
}
