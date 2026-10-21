import 'package:dio/dio.dart';
import 'package:sudoku/src/modules/leaderboard/data/response/leaderboard_dto.dart';
import 'package:sudoku/src/modules/leaderboard/data/response/player_standing_dto.dart';

// These two endpoints sit at the root, not under AppConfig.apiVersion.
abstract class LeaderboardAPIService {
  Future<LeaderboardDTO> getLeaderboard(int page, int size);

  Future<PlayerStandingDTO> getMyScore();
}

class LeaderboardAPIServiceImpl implements LeaderboardAPIService {
  final Dio dio;

  LeaderboardAPIServiceImpl(this.dio);

  @override
  Future<LeaderboardDTO> getLeaderboard(int page, int size) async {
    final response = await dio.get(
      '/leaderboard',
      queryParameters: {'page': page, 'size': size},
    );
    return LeaderboardDTO.fromJson(response.data);
  }

  @override
  Future<PlayerStandingDTO> getMyScore() async {
    final response = await dio.get('/scores/my_score');
    return PlayerStandingDTO.fromJson(response.data);
  }
}
