import 'package:equatable/equatable.dart';

/// The player's standing after a solved puzzle was scored.
class SubmissionResult extends Equatable {
  final int score;
  final int puzzlesCompleted;

  /// 1-based leaderboard position; null when the leaderboard is unavailable.
  final int? rank;

  const SubmissionResult({
    required this.score,
    required this.puzzlesCompleted,
    this.rank,
  });

  @override
  List<Object?> get props => [score, puzzlesCompleted, rank];
}
