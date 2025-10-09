import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/core/util/generic_result_state.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? selectedCell;
  late List<List<bool>> editableCells = [];

  //todo delete this
  List<List<int?>> board = [
    [null, null, null, null, null, null, null, null, null],
    [null, null, null, null, 9, null, null, null, null],
    [null, null, null, null, null, null, null, 9, null],
    [null, null, 9, null, null, null, 9, null, null],
    [null, 4, null, 9, null, null, null, null, null],
    [null, null, null, null, null, 4, null, null, null],
    [null, 6, null, null, null, null, null, null, null],
    [null, null, null, null, 8, null, null, null, null],
    [null, null, null, null, 9, null, null, null, null],
  ];

  @override
  void initState() {
    super.initState();
    context.read<MainBloc>().fetchSudokuChallenge();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: const Color(0xFF2C3E5A),
      appBar: PlatformAppBar(
        backgroundColor: const Color(0xFF2C3E5A),
        title: PlatformText(
          'Medium',
          style: const TextStyle(color: Color(0xFFFFFFFE), fontSize: 16),
        ),
        leading: PlatformIconButton(
          icon: Icon(PlatformIcons(context).back, color: Color(0xFFFFFFFE)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailingActions: [
          PlatformIconButton(
            icon: const Icon(Icons.pause, color: Color(0xFFFFFFFE)),
            onPressed: () {},
          ),
          PlatformIconButton(
            icon: Icon(
              context.platformIcon(
                material: Icons.notifications_outlined,
                cupertino: CupertinoIcons.bell,
              ),
              color: Color(0xFFFFFFFE),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<MainBloc, GenericResultState<SudokuGameModel>>(
          builder: (context, state) {
            if (state is Loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is Error<SudokuGameModel>) {
              return Center(
                child: Text(
                  state.toString(), //todo fix to `state.msg`
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else if (state is Success<SudokuGameModel>) {
              final model = state.value;
              if (editableCells.isEmpty) {
                editableCells = model!.puzzle
                    .map((row) => row.map((cell) => cell == 0).toList())
                    .toList();
              }
              return buildContent(model!);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget buildContent(SudokuGameModel model) {
    return Column(
      children: [
        const SizedBox(height: 20),
        buildTimer(),
        const SizedBox(height: 30),
        buildSudokuGrid(model),
        const Spacer(),
        buildNumberPad(model),
        const SizedBox(height: 20),
        buildBottomActions(context, model),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildTimer() {
    return const Text(
      '16:02',
      style: TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget buildSudokuGrid(SudokuGameModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(9, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(9, (col) {
              int cellIndex = row * 9 + col;
              bool isSelected = selectedCell == cellIndex;
              final cells = model.puzzle[row][col];
              bool isHighlighted = model.puzzle[row][col] == 9;

              bool isEditable = editableCells[row][col];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCell = cellIndex;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  margin: EdgeInsets.only(
                    right: (col + 1) % 3 == 0 && col != 8 ? 4 : 1,
                    bottom: (row + 1) % 3 == 0 && row != 8 ? 4 : 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4169E1) // Selected cell
                        : !isEditable
                        ? const Color(0xFF25324B) // Original fixed cell color
                        : const Color(0xFF2C3E5A), // Editable cell color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      cells == 0 ? '' : '$cells',
                      style: TextStyle(
                        color: isEditable ? Colors.white : Colors.white70,
                        fontSize: 18,
                        fontWeight: isEditable
                            ? FontWeight.w500
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget buildBottomActions(BuildContext context, SudokuGameModel model) {
    final bool isAndroid = isMaterial(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildActionButton(
            isAndroid ? Icons.undo : CupertinoIcons.arrow_uturn_left,
            'Undo',
          ),
          buildActionButton(
            isAndroid ? Icons.edit_outlined : CupertinoIcons.pencil,
            'Notes',
          ),
          buildActionButton(
            isAndroid ? Icons.lightbulb_outline : CupertinoIcons.lightbulb,
            'Hint',
          ),
          buildActionButton(
            isAndroid ? Icons.delete_outline : CupertinoIcons.delete,
            'Erase',
            onTap: () => eraseSelectedCell(model),
            onLongPress: () => eraseAllEditableCells(model),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2940),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget buildNumberPad(SudokuGameModel model) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2940),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(9, (index) {
          int number = index + 1;
          return GestureDetector(
            onTap: () {
              if (selectedCell != null) {
                int row = selectedCell! ~/ 9;
                int column = selectedCell! % 9;

                if (editableCells[row][column]) {
                  setState(() {
                    model.puzzle[row][column] = number;
                  });
                }
              }
            },
            child: Container(
              width: 34,
              height: 48,
              decoration: BoxDecoration(
                color: number == 4
                    ? const Color(0xFF4ECDC4)
                    : const Color(0xFF2C3E5A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void eraseSelectedCell(SudokuGameModel model) {
    if (selectedCell != null) {
      int row = selectedCell! ~/ 9;
      int col = selectedCell! % 9;
      if (editableCells[row][col]) {
        setState(() {
          model.puzzle[row][col] = 0;
        });
      }
    }
  }

  void eraseAllEditableCells(SudokuGameModel model) {
    setState(() {
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (editableCells[row][col]) {
            model.puzzle[row][col] = 0;
          }
        }
      }
    });
  }
}

// extension PlatformIconExtension on BuildContext {
//   IconData platformIcon({
//     required IconData material,
//     required IconData cupertino,
//   }) {
//     return isMaterial(this) ? material : cupertino;
//   }
// }
