import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sudoku/src/core/util/logger_service.dart';
import 'package:sudoku/src/modules/game/domain/model/submit_outcome.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/usecase/submit_solution_use_case.dart';

sealed class SubmitState {
  const SubmitState();
}

final class SubmitIdle extends SubmitState {
  const SubmitIdle();
}

final class Submitting extends SubmitState {
  const Submitting();
}

final class Submitted extends SubmitState {
  final SubmitOutcome outcome;

  const Submitted(this.outcome);
}

/// Sends a solved puzzle for scoring and keeps it so the submit can be
/// retried, or repeated after signing in.
class SubmitCubit extends Cubit<SubmitState> {
  final SubmitSolutionUseCase useCase;
  SudokuGameModel? _game;

  SubmitCubit(this.useCase) : super(const SubmitIdle());

  /// A retry, or signing in, can still get the puzzle scored.
  bool get canResubmit => switch (state) {
    Submitted(outcome: SignInRequired() || SubmitFailed()) => true,
    _ => false,
  };

  Future<void> submit(SudokuGameModel game) async {
    if (state is Submitting) return;
    if (game.id == _game?.id && state is Submitted && !canResubmit) return;
    _game = game;
    emit(const Submitting());
    SubmitOutcome outcome;
    try {
      outcome = await useCase.invoke(game);
    } catch (e, stackTrace) {
      LoggerService.logError(e, stackTrace: stackTrace);
      outcome = const SubmitFailed(SubmitSolutionUseCase.failedMessage);
    }
    // a new game may have started meanwhile
    if (!isClosed && identical(game, _game)) emit(Submitted(outcome));
  }

  Future<void> retry() async {
    final game = _game;
    if (game != null && canResubmit) await submit(game);
  }

  /// Forgets the last puzzle, for a new game.
  void reset() {
    _game = null;
    emit(const SubmitIdle());
  }
}
