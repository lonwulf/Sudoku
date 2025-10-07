import 'package:equatable/equatable.dart';

class SudokuGameModel extends Equatable {
  final String id;
  final String difficulty;
  final List<List<int>> puzzle;
  final List<List<int>> solution;

  const SudokuGameModel({
    required this.id,
    required this.difficulty,
    required this.puzzle,
    required this.solution,
  });

  @override
  List<Object?> get props => [id, difficulty, puzzle, solution];
}
