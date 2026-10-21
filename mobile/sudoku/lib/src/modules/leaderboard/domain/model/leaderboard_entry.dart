import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  /// 1-based position on the board.
  final int rank;
  final String userId;
  final String name;
  final int score;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.score,
  });

  @override
  List<Object?> get props => [rank, userId, name, score];
}
