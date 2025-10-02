import 'package:sudoku/src/core/util/APIResult.dart';
import 'package:sudoku/src/core/util/APIStatus.dart';
import 'package:sudoku/src/modules/game/data/source/SudokuRemoteDataSource.dart';
import 'package:sudoku/src/modules/game/domain/mapper/SudokuPuzzleMapper.dart';
import 'package:sudoku/src/modules/game/domain/model/SudokuGameModel.dart';
import 'package:sudoku/src/modules/game/domain/repository/MainRepository.dart';

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
