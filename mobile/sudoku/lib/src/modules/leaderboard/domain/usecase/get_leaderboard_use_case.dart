import 'package:sudoku/src/modules/leaderboard/domain/model/fetch_outcome.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_page.dart';
import 'package:sudoku/src/modules/leaderboard/domain/repository/leaderboard_repository.dart';

class GetLeaderboardUseCase {
  static const failedMessage =
      "Couldn't load the leaderboard. Check your connection and try again.";

  final LeaderboardRepository repository;

  GetLeaderboardUseCase(this.repository);

  Future<FetchOutcome<LeaderboardPage>> invoke(int page, int size) async =>
      FetchOutcome.from(
        await repository.fetchLeaderboard(page, size),
        failedMessage,
      );
}
