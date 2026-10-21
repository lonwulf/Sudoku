import 'package:sudoku/src/core/util/api_status.dart';
import 'package:sudoku/src/modules/auth/data/auth_service.dart';
import 'package:sudoku/src/modules/game/domain/model/submit_outcome.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';

class SubmitSolutionUseCase {
  static const failedMessage =
      "Couldn't save your score. Check your connection and try again.";

  final MainRepository repository;
  final AuthService authService;

  SubmitSolutionUseCase(this.repository, this.authService);

  Future<SubmitOutcome> invoke(SudokuGameModel game) async {
    if (authService.currentUser == null) return const SignInRequired();

    final result = await repository.submitSolution(game.id, game.board);
    switch (result.status) {
      case APIStatus.success:
        return Scored(result.result!);
      case APIStatus.error:
        return switch (result.code) {
          // the session ended between the check above and the request
          401 => const SignInRequired(),
          // expired, already scored, or not the solution: retrying can't help
          400 || 404 || 409 => Rejected(result.msg ?? failedMessage),
          429 => SubmitFailed(result.msg ?? failedMessage),
          _ => const SubmitFailed(failedMessage),
        };
    }
  }
}
