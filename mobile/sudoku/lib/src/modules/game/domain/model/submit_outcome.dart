import 'package:equatable/equatable.dart';
import 'package:sudoku/src/modules/game/domain/model/submission_result.dart';

/// What happened when a solved puzzle was sent for scoring.
sealed class SubmitOutcome extends Equatable {
  const SubmitOutcome();

  @override
  List<Object?> get props => [];
}

final class Scored extends SubmitOutcome {
  final SubmissionResult result;

  const Scored(this.result);

  @override
  List<Object?> get props => [result];
}

/// Scores are saved per player; sign in, then submit again.
final class SignInRequired extends SubmitOutcome {
  const SignInRequired();
}

/// Refused for good, e.g. the puzzle expired or was already scored.
final class Rejected extends SubmitOutcome {
  final String message;

  const Rejected(this.message);

  @override
  List<Object?> get props => [message];
}

/// Didn't get through (offline, rate limited, server error); worth retrying.
final class SubmitFailed extends SubmitOutcome {
  final String message;

  const SubmitFailed(this.message);

  @override
  List<Object?> get props => [message];
}
