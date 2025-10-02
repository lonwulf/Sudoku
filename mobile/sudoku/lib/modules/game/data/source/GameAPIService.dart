import 'package:dio/dio.dart';

abstract class GameAPIService{
  Future<SudokuGameDTO> getSudokuChallenge();
}

class GameAPIServiceImpl implements GameAPIService{
  final Dio dio;

  GameAPIServiceImpl(this.dio);

  @override
  Future<SudokuGameDTO> getSudokuChallenge() async{
    final response = await dio.get('path');
    return SudokuGameDTO.fromJson(response.data);
  }

}