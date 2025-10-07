import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/core/util/api_status.dart';
import 'package:sudoku/src/modules/game/data/source/sudoku_remote_data_source.dart';
import 'package:sudoku/src/modules/game/domain/mapper/sudoku_puzzle_mapper.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';

class MainRepositoryImpl extends MainRepository {
  final SudokuRemoteDataSource remoteDataSource;

  MainRepositoryImpl(this.remoteDataSource);

  @override
  Future<APIResult<SudokuGameModel>> fetchChallenge() async {
    final response = await remoteDataSource.fetchChallenge();
    switch (response.status) {
      case APIStatus.loading:
        return APIResult.loading();
      case APIStatus.success:
        final result = response.result!.toDomainModel();
        return APIResult.success(result);
      case APIStatus.error:
        return APIResult.error(
          code: response.code,
          msg: response.msg,
          httpResult: response.httpResult,
        );
      case null:
        return APIResult.error(
          code: response.code,
          msg: response.msg,
          httpResult: response.httpResult,
        );
    }
  }
}
