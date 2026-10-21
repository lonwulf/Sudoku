import 'package:sudoku/src/core/network/remote_data_source.dart';
import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/modules/leaderboard/data/response/leaderboard_dto.dart';
import 'package:sudoku/src/modules/leaderboard/data/response/player_standing_dto.dart';
import 'package:sudoku/src/modules/leaderboard/data/source/leaderboard_api_service.dart';

class LeaderboardRemoteDataSource extends RemoteDataSource {
  final LeaderboardAPIService apiService;

  LeaderboardRemoteDataSource(this.apiService);

  Future<APIResult<LeaderboardDTO>> fetchLeaderboard(int page, int size) {
    return safeApiCall(() {
      return apiService.getLeaderboard(page, size);
    });
  }

  Future<APIResult<PlayerStandingDTO>> fetchMyScore() {
    return safeApiCall(() {
      return apiService.getMyScore();
    });
  }
}
