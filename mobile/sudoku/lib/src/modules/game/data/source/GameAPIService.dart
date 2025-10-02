import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sudoku/src/modules/game/data/response/SudokuGameDTO.dart';

abstract class GameAPIService {
  Future<SudokuGameDTO> getSudokuChallenge();
}

class GameAPIServiceImpl implements GameAPIService {
  final Dio dio;

  GameAPIServiceImpl(this.dio);

  @override
  Future<SudokuGameDTO> getSudokuChallenge() async {
    final apiVersion = dotenv.env['API_VERSION'] ?? '';
    final response = await dio.get('$apiVersion/sudoku/puzzle/with-solution');
    return SudokuGameDTO.fromJson(response.data);
  }
}
