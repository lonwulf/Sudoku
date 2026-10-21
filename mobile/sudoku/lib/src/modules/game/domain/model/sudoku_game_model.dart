import 'package:equatable/equatable.dart';

class SudokuGameModel extends Equatable {
  final String id;
  final String difficulty;

  /// The starting grid; non-zero cells are givens and cannot be changed.
  final List<List<int>> puzzle;
  final List<List<int>> solution;

  /// The grid as the player has filled it in.
  final List<List<int>> board;

  /// Pencil marks per cell, indexed by `row * 9 + col`.
  final List<Set<int>> notes;

  SudokuGameModel({
    required this.id,
    required this.difficulty,
    required List<List<int>> puzzle,
    required List<List<int>> solution,
    List<List<int>>? board,
    List<Set<int>>? notes,
  }) : puzzle = _unmodifiable(puzzle),
       solution = _unmodifiable(solution),
       board = _unmodifiable(board ?? puzzle),
       notes = List.unmodifiable([
         for (final cell in notes ?? List.filled(81, const <int>{}))
           Set<int>.unmodifiable(cell),
       ]);

  bool isGiven(int row, int col) => puzzle[row][col] != 0;

  bool isCorrect(int row, int col) => board[row][col] == solution[row][col];

  Set<int> notesAt(int row, int col) => notes[row * 9 + col];

  /// Every cell matches the solution.
  bool get isSolved {
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        if (!isCorrect(row, col)) return false;
      }
    }
    return true;
  }

  /// Sets a cell's value, clearing its notes. A non-zero value is also
  /// removed from the notes of every cell in the same row, column and box.
  SudokuGameModel withCell(int row, int col, int value) {
    final nextBoard = [
      for (final cells in board) [...cells],
    ];
    nextBoard[row][col] = value;

    final nextNotes = [...notes];
    nextNotes[row * 9 + col] = const {};
    if (value != 0) {
      for (var i = 0; i < 81; i++) {
        if (_isPeer(row, col, i ~/ 9, i % 9) && nextNotes[i].contains(value)) {
          nextNotes[i] = {...nextNotes[i]}..remove(value);
        }
      }
    }
    return _copyWith(board: nextBoard, notes: nextNotes);
  }

  /// Adds or removes [number] from an empty cell's notes.
  SudokuGameModel withNoteToggled(int row, int col, int number) {
    final index = row * 9 + col;
    final cell = {...notes[index]};
    if (!cell.remove(number)) cell.add(number);
    final nextNotes = [...notes];
    nextNotes[index] = cell;
    return _copyWith(notes: nextNotes);
  }

  /// The cell to fill for a hint: [preferred] if it is editable and not yet
  /// correct, otherwise the first empty or incorrect cell. Null when solved.
  int? hintTarget(int? preferred) {
    bool needsHint(int index) {
      final row = index ~/ 9, col = index % 9;
      return !isGiven(row, col) && !isCorrect(row, col);
    }

    if (preferred != null && needsHint(preferred)) return preferred;
    for (var i = 0; i < 81; i++) {
      if (needsHint(i)) return i;
    }
    return null;
  }

  SudokuGameModel _copyWith({List<List<int>>? board, List<Set<int>>? notes}) =>
      SudokuGameModel(
        id: id,
        difficulty: difficulty,
        puzzle: puzzle,
        solution: solution,
        board: board ?? this.board,
        notes: notes ?? this.notes,
      );

  static bool _isPeer(int row, int col, int otherRow, int otherCol) =>
      row == otherRow ||
      col == otherCol ||
      (row ~/ 3 == otherRow ~/ 3 && col ~/ 3 == otherCol ~/ 3);

  static List<List<int>> _unmodifiable(List<List<int>> grid) =>
      List.unmodifiable([for (final row in grid) List<int>.unmodifiable(row)]);

  @override
  List<Object?> get props => [id, difficulty, puzzle, solution, board, notes];
}
