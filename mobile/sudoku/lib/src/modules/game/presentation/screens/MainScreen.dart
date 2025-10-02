import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/core/util/GenericResultState.dart';
import 'package:sudoku/src/modules/game/domain/model/SudokuGameModel.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/MainBloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? selectedCell;

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
            } else if (state is Error) {
              return Center(
                child: Text(
                  'state',//todo fix to `state.msg`
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else if (state is Success<SudokuGameModel>) {
              final model = state.value;
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
        buildBottomActions(context),
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
              bool isError = model.puzzle[row][col] == 9 && row == 4 && col == 3;

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
                    color: isError
                        ? const Color(0xFF8B4B68)
                        : isSelected
                        ? const Color(0xFF4169E1)
                        : isHighlighted
                        ? const Color(0xFF4B5B8B)
                        : const Color(0xFF2C3E5A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: cells != null
                        ? Text(
                            '$cells',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget buildBottomActions(BuildContext context) {
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
          ),
        ],
      ),
    );
  }

  Widget buildActionButton(IconData icon, String label) {
    return Column(
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
                setState(() {
                  int row = selectedCell! ~/ 9;
                  int column = selectedCell! % 9;
                  model.puzzle[row][column] = number;
                });
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
}

// extension PlatformIconExtension on BuildContext {
//   IconData platformIcon({
//     required IconData material,
//     required IconData cupertino,
//   }) {
//     return isMaterial(this) ? material : cupertino;
//   }
// }
