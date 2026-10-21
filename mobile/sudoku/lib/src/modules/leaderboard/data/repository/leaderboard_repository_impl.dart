import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/core/util/api_status.dart';
import 'package:sudoku/src/modules/leaderboard/data/source/leaderboard_remote_data_source.dart';
import 'package:sudoku/src/modules/leaderboard/domain/mapper/leaderboard_mapper.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_page.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/player_standing.dart';
import 'package:sudoku/src/modules/leaderboard/domain/repository/leaderboard_repository.dart';

class LeaderboardRepositoryImpl extends LeaderboardRepository {
  final LeaderboardRemoteDataSource remoteDataSource;

  LeaderboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<APIResult<LeaderboardPage>> fetchLeaderboard(
    int page,
    int size,
  ) async {
    final response = await remoteDataSource.fetchLeaderboard(page, size);
    switch (response.status) {
      case APIStatus.success:
        return APIResult.success(response.result!.toDomainModel());
      case APIStatus.error:
        return APIResult.error(
          code: response.code,
          msg: response.msg,
          httpResult: response.httpResult,
        );
    }
  }

  @override
  Future<APIResult<PlayerStanding>> fetchMyScore() async {
    final response = await remoteDataSource.fetchMyScore();
    switch (response.status) {
      case APIStatus.success:
        return APIResult.success(response.result!.toDomainModel());
      case APIStatus.error:
        return APIResult.error(
          code: response.code,
          msg: response.msg,
          httpResult: response.httpResult,
        );
    }
  }
}
