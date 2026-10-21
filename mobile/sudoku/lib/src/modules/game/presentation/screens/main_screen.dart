import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/core/util/generic_result_state.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
            } else if (state is Error<SudokuGameModel>) {
              return buildError(state.msg);
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

  Widget buildError(String? msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg == null || msg.isEmpty ? 'Something went wrong' : msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            PlatformTextButton(
              onPressed: () => context.read<MainBloc>().fetchSudokuChallenge(),
              child: const Text('Retry'),
            ),
          ],
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
        Flexible(child: Center(child: buildSudokuGrid(model))),
        const SizedBox(height: 20),
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

  // Cells are sized from the available space so the board fits narrow and
  // short screens instead of overflowing.
  Widget buildSudokuGrid(SudokuGameModel model) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2940),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: List.generate(9, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(9, (col) {
                    int cellIndex = row * 9 + col;
                    bool isSelected = selectedCell == cellIndex;
                    final cells = model.puzzle[row][col];
                    bool isHighlighted = model.puzzle[row][col] == 9;
                    bool isError =
                        model.puzzle[row][col] == 9 && row == 4 && col == 3;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCell = cellIndex;
                          });
                        },
                        child: Container(
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
                            child: cells != 0
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$cells',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
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
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
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
