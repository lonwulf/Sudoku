import 'package:equatable/equatable.dart';

/// The signed-in player's totals.
class PlayerStanding extends Equatable {
  final String name;
  final int score;
  final int puzzlesCompleted;

  /// 1-based leaderboard position; null until ranked or while the board is
  /// unavailable.
  final int? rank;

  const PlayerStanding({
    required this.name,
    required this.score,
    required this.puzzlesCompleted,
    this.rank,
  });

  @override
  List<Object?> get props => [name, score, puzzlesCompleted, rank];
}
