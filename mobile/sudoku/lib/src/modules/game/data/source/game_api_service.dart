import 'package:dio/dio.dart';
import 'package:sudoku/src/config/app_config.dart';
import 'package:sudoku/src/modules/game/data/response/submission_result_dto.dart';
import 'package:sudoku/src/modules/game/data/response/sudoku_game_dto.dart';

abstract class GameAPIService {
  Future<SudokuGameDTO> getSudokuChallenge(String difficulty);

  Future<SubmissionResultDTO> submitSolution(String id, List<List<int>> board);
}

class GameAPIServiceImpl implements GameAPIService {
  final Dio dio;

  GameAPIServiceImpl(this.dio);

  @override
  Future<SudokuGameDTO> getSudokuChallenge(String difficulty) async {
    final response = await dio.get(
      '${AppConfig.apiVersion}/sudoku/puzzle/with-solution',
      queryParameters: {'difficulty': difficulty},
    );
    return SudokuGameDTO.fromJson(response.data);
  }

  @override
  Future<SubmissionResultDTO> submitSolution(
    String id,
    List<List<int>> board,
  ) async {
    final response = await dio.post(
      '${AppConfig.apiVersion}/sudoku/puzzle/${Uri.encodeComponent(id)}/submit',
      data: board,
      // Dio only infers JSON for maps; a list body would go out as bytes
      options: Options(contentType: Headers.jsonContentType),
    );
    return SubmissionResultDTO.fromJson(response.data);
  }
}
