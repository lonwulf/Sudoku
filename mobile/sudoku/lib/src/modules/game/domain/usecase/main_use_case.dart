import 'package:sudoku/src/core/util/api_status.dart';
import 'package:sudoku/src/core/util/generic_use_case_result.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';

class MainUseCase {
  final MainRepository repository;

  MainUseCase(this.repository);

  Future<GenericUseCaseResult<SudokuGameModel?>> invoke() async {
    final result = await repository.fetchChallenge();
    switch (result.status) {
      case APIStatus.success:
        return GenericUseCaseResult(
          value: result.result!,
          isSuccessful: true,
        );
      case APIStatus.error:
        return GenericUseCaseResult(
          value: null,
          isSuccessful: false,
          msg: result.msg ?? 'Something went wrong',
        );
      default:
        return GenericUseCaseResult(value: null, isSuccessful: false);
    }
  }
}
