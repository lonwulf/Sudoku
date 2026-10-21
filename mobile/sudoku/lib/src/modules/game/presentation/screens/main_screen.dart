import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sudoku/src/core/util/generic_result_state.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/main_bloc.dart';
import 'package:sudoku/src/modules/game/presentation/components/game_timer.dart';
import 'package:sudoku/src/modules/game/presentation/components/number_pad_widget.dart';
import 'package:sudoku/src/modules/game/presentation/components/sudoku_grid.dart';
import 'package:sudoku/src/modules/reminder/presentation/components/reminder_button.dart';
import 'package:sudoku/src/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? selectedCell;

  /// When on, the number pad toggles pencil marks instead of entering values.
  bool notesMode = false;

  /// Stops the timer, hides the board and blocks input until resumed.
  bool paused = false;

  late final AppLifecycleListener lifecycleListener;

  @override
  void initState() {
    super.initState();
    context.read<MainBloc>().fetchSudokuChallenge();
    // Leaving the app pauses the game so the clock doesn't keep running.
    lifecycleListener = AppLifecycleListener(
      onHide: () => setState(() => paused = true),
    );
  }

  @override
  void dispose() {
    lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title:
            BlocSelector<MainBloc, GenericResultState<SudokuGameModel>, String>(
              selector: (state) => state is Success<SudokuGameModel>
                  ? state.value?.difficulty ?? ''
                  : '',
              builder: (context, difficulty) => PlatformText(
                _capitalize(difficulty),
                style: const TextStyle(
                  color: GameColors.onBackground,
                  fontSize: 16,
                ),
              ),
            ),
        trailingActions: [
          Semantics(
            button: true,
            label: paused ? 'Resume' : 'Pause',
            excludeSemantics: true,
            child: PlatformIconButton(
              icon: Icon(
                paused ? Icons.play_arrow : Icons.pause,
                color: GameColors.onBackground,
              ),
              onPressed: () => setState(() => paused = !paused),
            ),
          ),
          const ReminderButton(),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<MainBloc, GenericResultState<SudokuGameModel>>(
          builder: (context, state) {
            if (state is Loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is Failure<SudokuGameModel>) {
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
              style: const TextStyle(color: GameColors.errorText, fontSize: 16),
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

  /// Value in the selected cell, or 0 when nothing (or an empty cell) is
  /// selected. Cells and keys with the same digit are highlighted.
  int selectedValue(SudokuGameModel model) {
    final cell = selectedCell;
    return cell == null ? 0 : model.board[cell ~/ 9][cell % 9];
  }

  Widget buildContent(SudokuGameModel model) {
    return Column(
      children: [
        const SizedBox(height: 20),
        buildTimer(model),
        const SizedBox(height: 30),
        Flexible(
          child: Center(
            // Keeps the per-second timer repaint from repainting the board.
            child: RepaintBoundary(
              child: paused
                  ? buildPausedBoard()
                  : SudokuGrid(
                      model: model,
                      selectedCell: selectedCell,
                      onCellTap: (index) =>
                          setState(() => selectedCell = index),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        IgnorePointer(
          ignoring: paused,
          child: Opacity(
            opacity: paused ? 0.4 : 1,
            child: Column(
              children: [
                NumberPad(
                  selectedValue: selectedValue(model),
                  onNumber: (number) {
                    final cell = selectedCell;
                    if (cell == null) return;
                    final bloc = context.read<MainBloc>();
                    if (notesMode) {
                      bloc.toggleNote(cell ~/ 9, cell % 9, number);
                    } else {
                      bloc.enterNumber(cell ~/ 9, cell % 9, number);
                    }
                  },
                ),
                const SizedBox(height: 20),
                buildBottomActions(model),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Covers the board while paused so the puzzle can't be studied.
  Widget buildPausedBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: GameColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Paused',
                style: TextStyle(color: GameColors.onBackground, fontSize: 24),
              ),
              const SizedBox(height: 16),
              PlatformElevatedButton(
                onPressed: () => setState(() => paused = false),
                child: const Text('Resume'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTimer(SudokuGameModel model) {
    return GameTimer(
      key: ValueKey(model.id),
      paused: paused,
      style: const TextStyle(
        color: GameColors.onBackground,
        fontSize: 48,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget buildBottomActions(SudokuGameModel model) {
    final bool isAndroid = isMaterial(context);
    final bloc = context.read<MainBloc>();
    final cell = selectedCell;
    final canErase = cell != null && !model.isGiven(cell ~/ 9, cell % 9);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildActionButton(
            isAndroid ? Icons.undo : CupertinoIcons.arrow_uturn_left,
            'Undo',
            onTap: bloc.canUndo ? bloc.undo : null,
          ),
          buildActionButton(
            isAndroid ? Icons.edit_outlined : CupertinoIcons.pencil,
            'Notes',
            active: notesMode,
            onTap: () => setState(() => notesMode = !notesMode),
          ),
          buildActionButton(
            isAndroid ? Icons.lightbulb_outline : CupertinoIcons.lightbulb,
            'Hint',
            onTap: () {
              final target = bloc.hint(selectedCell);
              if (target != null) setState(() => selectedCell = target);
            },
          ),
          buildActionButton(
            isAndroid ? Icons.delete_outline : CupertinoIcons.delete,
            'Erase',
            onTap: canErase ? () => bloc.erase(cell ~/ 9, cell % 9) : null,
          ),
        ],
      ),
    );
  }

  /// A labelled action; [onTap] null disables it, [active] marks a toggle on.
  Widget buildActionButton(
    IconData icon,
    String label, {
    required VoidCallback? onTap,
    bool active = false,
  }) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      toggled: label == 'Notes' ? active : null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active ? GameColors.accent : GameColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: active ? GameColors.onAccent : GameColors.muted,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? GameColors.accent : GameColors.subtle,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
