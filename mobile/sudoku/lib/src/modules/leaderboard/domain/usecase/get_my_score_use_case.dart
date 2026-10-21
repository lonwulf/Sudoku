import 'package:sudoku/src/modules/leaderboard/domain/model/fetch_outcome.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/player_standing.dart';
import 'package:sudoku/src/modules/leaderboard/domain/repository/leaderboard_repository.dart';

class GetMyScoreUseCase {
  static const failedMessage =
      "Couldn't load your score. Check your connection and try again.";

  final LeaderboardRepository repository;

  GetMyScoreUseCase(this.repository);

  Future<FetchOutcome<PlayerStanding>> invoke() async =>
      FetchOutcome.from(await repository.fetchMyScore(), failedMessage);
}
