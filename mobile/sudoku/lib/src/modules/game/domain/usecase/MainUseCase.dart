import 'package:sudoku/src/core/util/APIStatus.dart';
import 'package:sudoku/src/core/util/GenericUseCaseResult.dart';
import 'package:sudoku/src/modules/game/domain/model/SudokuGameModel.dart';
import 'package:sudoku/src/modules/game/domain/repository/MainRepository.dart';

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
