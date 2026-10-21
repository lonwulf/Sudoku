import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/generic_result_state.dart';
import 'package:sudoku/src/core/util/logger_service.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';

class MainBloc extends Cubit<GenericResultState<SudokuGameModel>> {
  final MainUseCase useCase;

  MainBloc(this.useCase) : super(const Loading());

  Future<void> fetchSudokuChallenge() async {
    emit(Loading());
    try {
      final result = await useCase.invoke();
      if (result.isSuccessful) {
        emit(Success(result.value));
      } else {
        emit(Failure(result.msg));
      }
    } catch (e) {
      LoggerService.logError(e);
      emit(Failure("Unexpected error: ${e.toString()}"));
    }
  }

  void enterNumber(int row, int col, int number) {
    final current = state;
    if (current is! Success<SudokuGameModel>) return;
    final model = current.value;
    if (model == null || model.isGiven(row, col)) return;
    emit(Success(model.withCell(row, col, number)));
  }
}
