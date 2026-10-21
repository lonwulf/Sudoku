import 'package:dio/dio.dart';
import 'package:sudoku/src/config/app_config.dart';
import 'package:sudoku/src/modules/game/data/response/sudoku_game_dto.dart';

abstract class GameAPIService {
  Future<SudokuGameDTO> getSudokuChallenge();
}

class GameAPIServiceImpl implements GameAPIService {
  final Dio dio;

  GameAPIServiceImpl(this.dio);

  @override
  Future<SudokuGameDTO> getSudokuChallenge() async {
    final response = await dio.get(
      '${AppConfig.apiVersion}/sudoku/puzzle/with-solution',
    );
    return SudokuGameDTO.fromJson(response.data);
  }
}
