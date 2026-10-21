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
        emit(Success(result.value));
      } else {
        emit(Failure(result.msg));
      }
    } catch (e) {
      LoggerService.logError(e);
      if (!isClosed) emit(Failure("Unexpected error: ${e.toString()}"));
    }
  }

  void enterNumber(int row, int col, int number) {
    final current = state;
    if (current is! Success<SudokuGameModel>) return;
    final model = current.value;
    if (model == null || model.isGiven(row, col)) return;
    emit(Success(model.withCell(row, col, number)));
  }

  @override
  Future<void> close() async {
    await networkSubscription.cancel();
    return super.close();
  }
}
