import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/core/util/api_status.dart';
import 'package:sudoku/src/modules/game/data/source/sudoku_remote_data_source.dart';
import 'package:sudoku/src/modules/game/domain/mapper/submission_result_mapper.dart';
import 'package:sudoku/src/modules/game/domain/mapper/sudoku_puzzle_mapper.dart';
import 'package:sudoku/src/modules/game/domain/model/difficulty.dart';
import 'package:sudoku/src/modules/game/domain/model/submission_result.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';

class MainRepositoryImpl extends MainRepository {
  final SudokuRemoteDataSource remoteDataSource;

  MainRepositoryImpl(this.remoteDataSource);

  @override
  Future<APIResult<SudokuGameModel>> fetchChallenge(
    Difficulty difficulty,
  ) async {
    final response = await remoteDataSource.fetchChallenge(difficulty.name);
    switch (response.status) {
      case APIStatus.success:
        final result = response.result!.toDomainModel();
        return APIResult.success(result);
      case APIStatus.error:
        return APIResult.error(
          code: response.code,
          msg: response.msg,
          httpResult: response.httpResult,
        );
    }
  }

  @override
  Future<APIResult<SubmissionResult>> submitSolution(
    String id,
    List<List<int>> board,
  ) async {
    final response = await remoteDataSource.submitSolution(id, board);
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
