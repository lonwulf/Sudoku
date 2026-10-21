import 'package:flutter/material.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/theme/app_theme.dart';

/// The 9x9 board. Cells are sized from the available space so the board
/// fits narrow and short screens instead of overflowing.
class SudokuGrid extends StatelessWidget {
  final SudokuGameModel model;
  final int? selectedCell;
  final ValueChanged<int> onCellTap;

  const SudokuGrid({
    super.key,
    required this.model,
    required this.selectedCell,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final cell = selectedCell;
    final selectedValue = cell == null ? 0 : model.board[cell ~/ 9][cell % 9];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GameColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(9, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(9, (col) {
                    final index = row * 9 + col;
                    final value = model.board[row][col];
                    final isGiven = model.isGiven(row, col);
                    final isSelected = selectedCell == index;
                    return Expanded(
                      child: SudokuCell(
                        row: row,
                        col: col,
                        value: value,
                        isGiven: isGiven,
                        isSelected: isSelected,
                        isHighlighted:
                            !isSelected && value != 0 && value == selectedValue,
                        isError:
                            !isGiven &&
                            value != 0 &&
                            value != model.solution[row][col],
                        onTap: () => onCellTap(index),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class SudokuCell extends StatelessWidget {
  final int row;
  final int col;
  final int value;
  final bool isGiven;
  final bool isSelected;
  final bool isHighlighted;
  final bool isError;
  final VoidCallback onTap;

  const SudokuCell({
    super.key,
    required this.row,
    required this.col,
    required this.value,
    required this.isGiven,
    required this.isSelected,
    required this.isHighlighted,
    required this.isError,
    required this.onTap,
  });

  String get semanticLabel {
    final parts = [
      'Row ${row + 1}, column ${col + 1}',
      value == 0 ? 'empty' : '$value',
      if (isGiven) 'given',
      if (isError) 'incorrect',
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(
            right: (col + 1) % 3 == 0 && col != 8 ? 4 : 1,
            bottom: (row + 1) % 3 == 0 && row != 8 ? 4 : 1,
          ),
          decoration: BoxDecoration(
            color: isError
                ? GameColors.conflict
                : isSelected
                ? GameColors.selected
                : isHighlighted
                ? GameColors.highlighted
                : GameColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: value != 0
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$value',
                      style: TextStyle(
                        color: isGiven
                            ? GameColors.onBackground
                            : GameColors.playerEntry,
                        fontSize: 18,
                        fontWeight: isGiven ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
