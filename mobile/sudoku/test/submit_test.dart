import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/modules/game/data/source/game_api_service.dart';
import 'package:sudoku/src/modules/game/domain/model/submission_result.dart';
import 'package:sudoku/src/modules/game/domain/model/submit_outcome.dart';
import 'package:sudoku/src/modules/game/domain/usecase/submit_solution_use_case.dart';
import 'package:sudoku/src/modules/game/presentation/bloc/submit_cubit.dart';

import 'fixtures.dart';

const _result = SubmissionResult(score: 40, puzzlesCompleted: 3, rank: 2);

/// Answers every request with [status] and [body], recording what was sent.
class _StubAdapter implements HttpClientAdapter {
  final int status;
  final Object body;
  final requests = <RequestOptions>[];

  _StubAdapter(this.status, this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('GameAPIServiceImpl', () {
    test('asks for a puzzle at the chosen difficulty', () async {
      final adapter = _StubAdapter(200, {'id': 'p1', 'difficulty': 'hard'});
      final api = GameAPIServiceImpl(Dio()..httpClientAdapter = adapter);

      final dto = await api.getSudokuChallenge('hard');

      expect(dto.difficulty, 'hard');
      expect(
        adapter.requests.single.uri.path,
        endsWith('/puzzle/with-solution'),
      );
      expect(adapter.requests.single.uri.queryParameters, {
        'difficulty': 'hard',
      });
    });

    test('posts the board to the puzzle and reads the score', () async {
      final adapter = _StubAdapter(200, {
        'userId': 'sub-1',
        'displayName': 'Test Player',
        'puzzlesCompleted': 3,
        'leaderboardScore': 40,
        'rank': 2,
      });
      final api = GameAPIServiceImpl(Dio()..httpClientAdapter = adapter);

      final dto = await api.submitSolution('p1', testSolution);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, endsWith('/sudoku/puzzle/p1/submit'));
      expect(request.data, testSolution);
      expect(request.contentType, Headers.jsonContentType);
      expect(dto.leaderboardScore, 40);
      expect(dto.rank, 2);
    });

    test('reads a score without a rank', () async {
      final adapter = _StubAdapter(200, {
        'puzzlesCompleted': 1,
        'leaderboardScore': 10,
        'rank': null,
      });
      final api = GameAPIServiceImpl(Dio()..httpClientAdapter = adapter);

      expect((await api.submitSolution('p1', testSolution)).rank, isNull);
    });
  });

  group('SubmitSolutionUseCase', () {
    Future<SubmitOutcome> submit(
      APIResult<SubmissionResult> response, {
      bool signedIn = true,
      FakeMainRepository? repository,
    }) {
      final repo = repository ?? FakeMainRepository(submitResult: response);
      return SubmitSolutionUseCase(
        repo,
        FakeAuthService(user: signedIn ? testUser : null),
      ).invoke(nearlySolvedGame());
    }

    test('scores the puzzle', () async {
      expect(await submit(APIResult.success(_result)), const Scored(_result));
    });

    test('asks to sign in without calling the backend', () async {
      final repository = FakeMainRepository();

      final outcome = await submit(
        APIResult.success(_result),
        signedIn: false,
        repository: repository,
      );

      expect(outcome, const SignInRequired());
      expect(repository.submitted, isEmpty);
    });

    test(
      'asks to sign in again when the backend refuses the session',
      () async {
        expect(
          await submit(APIResult.error(code: 401)),
          const SignInRequired(),
        );
      },
    );

    test('expired or already scored puzzles are final', () async {
      expect(
        await submit(
          APIResult.error(code: 400, msg: 'Puzzle expired or not found'),
        ),
        const Rejected('Puzzle expired or not found'),
      );
      expect(
        await submit(
          APIResult.error(code: 409, msg: 'Puzzle already submitted'),
        ),
        const Rejected('Puzzle already submitted'),
      );
    });

    test('rate limits and outages can be retried', () async {
      expect(
        await submit(
          APIResult.error(code: 429, msg: 'Too many requests, retry in 12s'),
        ),
        const SubmitFailed('Too many requests, retry in 12s'),
      );
      expect(
        await submit(APIResult.error(code: 503, msg: 'Service unavailable')),
        const SubmitFailed(SubmitSolutionUseCase.failedMessage),
      );
      expect(
        await submit(APIResult.error(msg: 'Connection refused')),
        const SubmitFailed(SubmitSolutionUseCase.failedMessage),
      );
    });
  });

  group('SubmitCubit', () {
    late FakeAuthService auth;
    late FakeMainRepository repository;
    late SubmitCubit cubit;

    setUp(() {
      auth = FakeAuthService(user: testUser);
      repository = FakeMainRepository();
      cubit = SubmitCubit(SubmitSolutionUseCase(repository, auth));
    });

    tearDown(() => cubit.close());

    test('scores a puzzle only once', () async {
      final game = nearlySolvedGame();

      await cubit.submit(game);
      await cubit.submit(game);
      await cubit.retry();

      expect(repository.submitted, ['nearly']);
      expect((cubit.state as Submitted).outcome, const Scored(_result));
    });

    test('retries after a failure', () async {
      repository.submitResult = APIResult.error(code: 503);
      await cubit.submit(nearlySolvedGame());
      expect(cubit.canResubmit, isTrue);

      repository.submitResult = APIResult.success(_result);
      await cubit.retry();

      expect(repository.submitted, ['nearly', 'nearly']);
      expect((cubit.state as Submitted).outcome, const Scored(_result));
    });

    test('a new game drops a result still in flight', () async {
      final pending = cubit.submit(nearlySolvedGame());
      cubit.reset();
      await pending;

      expect(cubit.state, isA<SubmitIdle>());
    });
  });
}
