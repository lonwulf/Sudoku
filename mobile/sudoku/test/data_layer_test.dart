import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/core/util/api_status.dart';
import 'package:sudoku/src/modules/game/data/response/submission_result_dto.dart';
import 'package:sudoku/src/modules/game/data/response/sudoku_game_dto.dart';
import 'package:sudoku/src/modules/game/data/source/game_api_service.dart';
import 'package:sudoku/src/modules/game/data/source/sudoku_remote_data_source.dart';
import 'package:sudoku/src/modules/game/domain/mapper/sudoku_puzzle_mapper.dart';
import 'package:sudoku/src/modules/game/domain/model/difficulty.dart';
import 'package:sudoku/src/modules/game/domain/model/submission_result.dart';
import 'package:sudoku/src/modules/game/domain/model/sudoku_game_model.dart';
import 'package:sudoku/src/modules/game/domain/repository/main_repository.dart';
import 'package:sudoku/src/modules/game/domain/usecase/main_use_case.dart';

import 'fixtures.dart';

class _FakeApiService implements GameAPIService {
  final Future<SudokuGameDTO> Function() handler;

  _FakeApiService(this.handler);

  @override
  Future<SudokuGameDTO> getSudokuChallenge(String difficulty) => handler();

  @override
  Future<SubmissionResultDTO> submitSolution(
    String id,
    List<List<int>> board,
  ) => throw UnimplementedError();
}

class _FakeRepository implements MainRepository {
  final APIResult<SudokuGameModel> result;

  _FakeRepository(this.result);

  @override
  Future<APIResult<SudokuGameModel>> fetchChallenge(
    Difficulty difficulty,
  ) async => result;

  @override
  Future<APIResult<SubmissionResult>> submitSolution(
    String id,
    List<List<int>> board,
  ) => throw UnimplementedError();
}

DioException _httpError(int status, Object? data) {
  final options = RequestOptions(path: '/puzzle');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  group('SudokuGameDTO', () {
    test('parses the backend response and maps it to the domain model', () {
      final json = {
        'id': 'cd137a6d',
        'difficulty': 'medium',
        'puzzle': testPuzzle,
        'solution': testSolution,
      };

      final model = SudokuGameDTO.fromJson(json).toDomainModel();

      expect(model.id, 'cd137a6d');
      expect(model.puzzle, testPuzzle);
      expect(model.solution, testSolution);
      expect(model.board, testPuzzle);
    });

    test('falls back to empty grids when fields are missing', () {
      final model = SudokuGameDTO.fromJson({}).toDomainModel();

      expect(model.id, '');
      expect(model.board.expand((row) => row), everyElement(0));
    });
  });

  group('SudokuRemoteDataSource', () {
    test('wraps a successful call', () async {
      final source = SudokuRemoteDataSource(
        _FakeApiService(() async => SudokuGameDTO('id', 'easy', null, null)),
      );

      final result = await source.fetchChallenge('medium');

      expect(result.status, APIStatus.success);
      expect(result.result?.id, 'id');
    });

    test('maps a 4xx response to a client error with its message', () async {
      final source = SudokuRemoteDataSource(
        _FakeApiService(() => throw _httpError(404, {'message': 'Not found'})),
      );

      final result = await source.fetchChallenge('medium');

      expect(result.status, APIStatus.error);
      expect(result.code, 404);
      expect(result.msg, 'Not found');
      expect(result.httpResult, HttpResult.clientError);
    });

    test('maps a 5xx response to a server error', () async {
      final source = SudokuRemoteDataSource(
        _FakeApiService(() => throw _httpError(503, null)),
      );

      final result = await source.fetchChallenge('medium');

      expect(result.code, 503);
      expect(result.httpResult, HttpResult.serverError);
    });
  });

  group('MainUseCase', () {
    test('reports a successful fetch as successful', () async {
      final useCase = MainUseCase(
        _FakeRepository(APIResult.success(testGame())),
      );

      final result = await useCase.invoke(Difficulty.medium);

      expect(result.isSuccessful, isTrue);
      expect(result.value, testGame());
    });

    test('passes the error message through', () async {
      final useCase = MainUseCase(
        _FakeRepository(APIResult.error(code: 500, msg: 'Server down')),
      );

      final result = await useCase.invoke(Difficulty.medium);

      expect(result.isSuccessful, isFalse);
      expect(result.value, isNull);
      expect(result.msg, 'Server down');
    });
  });
}
