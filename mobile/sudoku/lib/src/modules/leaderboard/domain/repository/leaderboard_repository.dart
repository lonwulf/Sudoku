import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_page.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/player_standing.dart';

abstract class LeaderboardRepository {
  /// [page] is 0-based, [size] entries per page.
  Future<APIResult<LeaderboardPage>> fetchLeaderboard(int page, int size);

  Future<APIResult<PlayerStanding>> fetchMyScore();
}
