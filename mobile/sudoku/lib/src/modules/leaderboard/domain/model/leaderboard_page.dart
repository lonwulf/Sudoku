import 'package:equatable/equatable.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_entry.dart';

/// One page of the board, plus the player's own place on it.
class LeaderboardPage extends Equatable {
  final List<LeaderboardEntry> top;

  /// Null until the player has scored.
  final LeaderboardEntry? me;

  /// Players just above and below [me].
  final List<LeaderboardEntry> nearby;

  /// Set while the server rebuilds the board: when to ask again.
  final int? warmingUpRetrySeconds;

  const LeaderboardPage({
    this.top = const [],
    this.me,
    this.nearby = const [],
    this.warmingUpRetrySeconds,
  });

  bool get warmingUp => warmingUpRetrySeconds != null;

  @override
  List<Object?> get props => [top, me, nearby, warmingUpRetrySeconds];
}
