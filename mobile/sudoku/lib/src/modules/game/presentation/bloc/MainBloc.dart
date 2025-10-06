import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/GenericResultState.dart';
import 'package:sudoku/src/core/util/LoggerService.dart';
import 'package:sudoku/src/modules/game/domain/model/SudokuGameModel.dart';
import 'package:sudoku/src/modules/game/domain/usecase/MainUseCase.dart';

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
        emit(Error(result.msg));
      }
    } catch (e) {
      LoggerService.logError(e);
      emit(Error("Unexpected error: ${e.toString()}"));
    }
  }
}
