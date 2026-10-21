import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/generic_result_state.dart';
import 'package:sudoku/src/core/util/logger_service.dart';
import 'package:sudoku/src/core/util/network_monitor.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';

class MainBloc extends Cubit<GenericResultState<SudokuGameModel>> {
  static const noConnectionMessage =
      'No internet connection.\nThe puzzle will load when you are back online.';

  final MainUseCase useCase;
  final NetworkMonitor networkMonitor;
  late final StreamSubscription<bool> networkSubscription;

  /// Last known connectivity; null until the first check or change.
  bool? isOnline;

  /// Earlier boards of the current puzzle, most recent last, for undo.
  final List<SudokuGameModel> _history = [];

  bool get canUndo => _history.isNotEmpty;

  MainBloc(this.useCase, this.networkMonitor) : super(const Loading()) {
    networkSubscription = networkMonitor.networkChangeEvent.listen(
      onNetworkChange,
    );
  }

  /// Retries a failed load when the device comes back online. An already
  /// loaded puzzle is left alone when the connection drops.
  void onNetworkChange(bool online) {
    final reconnected = online && isOnline == false;
    isOnline = online;
    if (reconnected && state is Failure) {
      fetchSudokuChallenge();
    }
  }

  Future<void> fetchSudokuChallenge() async {
    emit(Loading());
    try {
      final online = await networkMonitor.isConnected();
      if (isClosed) return;
      if (!online) {
        isOnline = false;
        emit(const Failure(noConnectionMessage));
        return;
      }
      final result = await useCase.invoke();
      if (isClosed) return;
      if (result.isSuccessful) {
        _history.clear();
        emit(Success(result.value));
      } else {
        emit(Failure(result.msg));
      }
    } catch (e) {
      LoggerService.logError(e);
      if (!isClosed) emit(Failure("Unexpected error: ${e.toString()}"));
    }
  }

  SudokuGameModel? get _model {
    final current = state;
    return current is Success<SudokuGameModel> ? current.value : null;
  }

  /// Emits [next] and remembers the current board so it can be undone.
  void _apply(SudokuGameModel current, SudokuGameModel next) {
    if (next == current) return;
    _history.add(current);
    emit(Success(next));
  }

  void enterNumber(int row, int col, int number) {
    final model = _model;
    if (model == null || model.isGiven(row, col)) return;
    _apply(model, model.withCell(row, col, number));
  }

  /// Toggles a pencil mark; only empty, editable cells take notes.
  void toggleNote(int row, int col, int number) {
    final model = _model;
    if (model == null ||
        model.isGiven(row, col) ||
        model.board[row][col] != 0) {
      return;
    }
    _apply(model, model.withNoteToggled(row, col, number));
  }

  /// Clears a cell's value and notes.
  void erase(int row, int col) {
    final model = _model;
    if (model == null || model.isGiven(row, col)) return;
    _apply(model, model.withCell(row, col, 0));
  }

  /// Fills [selectedCell] with its solution, or the first empty or wrong
  /// cell when the selected one doesn't need a hint. Returns the cell filled,
  /// or null when the puzzle is already solved.
  int? hint(int? selectedCell) {
    final model = _model;
    final target = model?.hintTarget(selectedCell);
    if (model == null || target == null) return null;
    final row = target ~/ 9, col = target % 9;
    _apply(model, model.withCell(row, col, model.solution[row][col]));
    return target;
  }

  void undo() {
    if (_model == null || _history.isEmpty) return;
    emit(Success(_history.removeLast()));
  }

  @override
  Future<void> close() async {
    await networkSubscription.cancel();
    return super.close();
  }
}
