import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/src/core/util/api_result.dart';
import 'package:sudoku/src/modules/auth/presentation/bloc/auth_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/data/response/leaderboard_dto.dart';
import 'package:sudoku/src/modules/leaderboard/data/source/leaderboard_api_service.dart';
import 'package:sudoku/src/modules/leaderboard/domain/mapper/leaderboard_mapper.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/fetch_outcome.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_entry.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/leaderboard_page.dart';
import 'package:sudoku/src/modules/leaderboard/domain/model/player_standing.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_leaderboard_use_case.dart';
import 'package:sudoku/src/modules/leaderboard/domain/usecase/get_my_score_use_case.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/bloc/leaderboard_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/bloc/my_score_cubit.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:sudoku/src/modules/leaderboard/presentation/screens/my_score_screen.dart';

import 'fixtures.dart';

const _size = LeaderboardCubit.pageSize;

APIResult<LeaderboardPage> _page(
  List<LeaderboardEntry> top, {
  LeaderboardEntry? me,
  List<LeaderboardEntry> nearby = const [],
}) => APIResult.success(LeaderboardPage(top: top, me: me, nearby: nearby));

/// Answers every request with [body], recording what was asked for.
class _StubAdapter implements HttpClientAdapter {
  final Object body;
  final requests = <RequestOptions>[];

  _StubAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('LeaderboardAPIServiceImpl', () {
    test('asks for one page of the board', () async {
      final adapter = _StubAdapter({'state': 'ready', 'global': []});
      final api = LeaderboardAPIServiceImpl(Dio()..httpClientAdapter = adapter);

      await api.getLeaderboard(2, 20);

      expect(adapter.requests.single.uri.path, '/leaderboard');
      expect(adapter.requests.single.uri.queryParameters, {
        'page': '2',
        'size': '20',
      });
    });

    test("reads the player's score", () async {
      final adapter = _StubAdapter({
        'userId': 'sub-1',
        'displayName': 'Test Player',
        'puzzlesCompleted': 4,
        'leaderboardScore': 70,
        'rank': null,
      });
      final api = LeaderboardAPIServiceImpl(Dio()..httpClientAdapter = adapter);

      final standing = (await api.getMyScore()).toDomainModel();

      expect(adapter.requests.single.uri.path, '/scores/my_score');
      expect(
        standing,
        const PlayerStanding(
          name: 'Test Player',
          score: 70,
          puzzlesCompleted: 4,
        ),
      );
    });
  });

  group('mapping', () {
    test('a board being rebuilt asks to come back later', () {
      final page = LeaderboardDTO.fromJson({
        'global': [],
        'me': null,
        'nearby': [],
        'state': 'initializing',
        'message': 'Leaderboard is warming up, please retry later',
        'retryAfterSeconds': 4,
      }).toDomainModel();

      expect(page.warmingUp, isTrue);
      expect(page.warmingUpRetrySeconds, 4);
    });

    test('a ready board keeps ranks and names unnamed players', () {
      final page = LeaderboardDTO.fromJson({
        'global': [
          {
            'rank': 1,
            'userId': 'a',
            'displayName': 'Ann',
            'leaderboardScore': 90,
          },
          {
            'rank': 2,
            'userId': 'b',
            'displayName': null,
            'leaderboardScore': 80,
          },
        ],
        'me': {
          'rank': 2,
          'userId': 'b',
          'displayName': null,
          'leaderboardScore': 80,
        },
        'nearby': [],
        'state': 'ready',
      }).toDomainModel();

      expect(page.warmingUp, isFalse);
      expect(page.top.map((e) => e.name), ['Ann', 'Player']);
      expect(page.me?.rank, 2);
    });

    test('errors become sign-in, server messages, or a generic failure', () {
      FetchOutcome<int> outcome(int? code, [String? msg]) =>
          FetchOutcome.from(APIResult.error(code: code, msg: msg), 'generic');

      expect(
        FetchOutcome.from(APIResult.success(1), 'generic'),
        const Fetched(1),
      );
      expect(outcome(401), const NeedsSignIn<int>());
      expect(
        outcome(400, 'size must be ≤ 100'),
        const FetchFailed<int>('size must be ≤ 100'),
      );
      expect(outcome(429, 'Too many'), const FetchFailed<int>('Too many'));
      expect(
        outcome(503, 'Service Unavailable'),
        const FetchFailed<int>('generic'),
      );
      expect(
        outcome(null, 'SocketException'),
        const FetchFailed<int>('generic'),
      );
    });
  });

  group('LeaderboardCubit', () {
    late FakeLeaderboardRepository repository;
    late LeaderboardCubit cubit;

    setUp(() {
      repository = FakeLeaderboardRepository();
      cubit = LeaderboardCubit(GetLeaderboardUseCase(repository));
    });

    tearDown(() => cubit.close());

    test('a full page means there may be more', () async {
      repository.pages[0] = _page(testEntries(1, _size));

      await cubit.load();

      expect(cubit.state.status, LeaderboardStatus.ready);
      expect(cubit.state.hasMore, isTrue);
    });

    test('loads further pages without listing anyone twice', () async {
      repository.pages[0] = _page(testEntries(1, _size));
      // player 20 moved down a place between pages
      repository.pages[1] = _page(testEntries(20, 5));
      await cubit.load();

      await cubit.loadMore();
      await cubit.loadMore();

      expect(repository.requestedPages, [0, 1]);
      expect(cubit.state.top.map((e) => e.userId), [
        for (var rank = 1; rank <= 24; rank++) 'u$rank',
      ]);
      expect(cubit.state.hasMore, isFalse);
    });

    test('a failed page can be retried', () async {
      repository.pages[0] = _page(testEntries(1, _size));
      repository.pages[1] = APIResult.error(code: 503);
      await cubit.load();

      await cubit.loadMore();
      expect(cubit.state.loadMoreFailed, isTrue);
      expect(cubit.state.top, hasLength(_size));

      repository.pages[1] = _page(testEntries(21, 3));
      await cubit.loadMore();
      expect(cubit.state.loadMoreFailed, isFalse);
      expect(cubit.state.top, hasLength(_size + 3));
    });

    test('shows the players around a player below the loaded page', () async {
      repository.pages[0] = _page(
        testEntries(1, 3),
        me: testEntries(50, 1).single,
        nearby: testEntries(48, 5),
      );
      await cubit.load();
      expect(cubit.state.showNearby, isTrue);

      repository.pages[0] = _page(
        testEntries(1, 3),
        me: testEntries(2, 1).single,
        nearby: testEntries(1, 3),
      );
      await cubit.load();
      expect(cubit.state.showNearby, isFalse);
    });

    test('waits while the board warms up, then loads it', () async {
      repository.pages[0] = APIResult.success(
        const LeaderboardPage(warmingUpRetrySeconds: 0),
      );
      await cubit.load();
      expect(cubit.state.status, LeaderboardStatus.warmingUp);

      repository.pages[0] = _page(testEntries(1, 2));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.status, LeaderboardStatus.ready);
      expect(repository.requestedPages, [0, 0]);
    });

    test(
      'a refresh keeps the board on screen, a 401 asks to sign in',
      () async {
        repository.pages[0] = _page(testEntries(1, 2));
        await cubit.load();
        final states = <LeaderboardStatus>[];
        final subscription = cubit.stream.listen((s) => states.add(s.status));

        repository.pages[0] = _page(testEntries(1, 3));
        await cubit.load(refresh: true);
        await pumpEventQueue();
        expect(states, [LeaderboardStatus.ready]);
        expect(cubit.state.top, hasLength(3));

        repository.pages[0] = APIResult.error(code: 401);
        await cubit.load();
        expect(cubit.state.status, LeaderboardStatus.signInRequired);
        await subscription.cancel();
      },
    );
  });

  group('MyScoreCubit', () {
    test('loads the totals, or asks to sign in', () async {
      final repository = FakeLeaderboardRepository();
      final cubit = MyScoreCubit(GetMyScoreUseCase(repository));
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.standing, testStanding);

      repository.myScore = APIResult.error(code: 401);
      await cubit.load();
      expect(cubit.state.status, MyScoreStatus.signInRequired);

      repository.myScore = APIResult.error(msg: 'offline');
      await cubit.load();
      expect(cubit.state.status, MyScoreStatus.failed);
      expect(cubit.state.message, GetMyScoreUseCase.failedMessage);
    });
  });

  group('LeaderboardScreen', () {
    Widget screen(FakeLeaderboardRepository repository, FakeAuthService auth) =>
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => AuthCubit(auth)),
              BlocProvider(
                create: (_) =>
                    LeaderboardCubit(GetLeaderboardUseCase(repository))..load(),
              ),
            ],
            child: const LeaderboardScreen(),
          ),
        );

    testWidgets('pins the player and shows who is around them', (tester) async {
      final repository = FakeLeaderboardRepository(
        pages: {
          0: _page(
            testEntries(1, 3),
            me: testEntries(50, 1).single,
            nearby: testEntries(49, 3),
          ),
        },
      );
      await tester.pumpWidget(
        screen(repository, FakeAuthService(user: testUser)),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('You are ranked 50 with 950 points'),
        findsOneWidget,
      );
      expect(find.text('Around you'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Rank 50, Player 50, you, 950 points'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Rank 1, Player 1, 999 points'),
        findsOneWidget,
      );
    });

    testWidgets('loads the next page when scrolled to the end', (tester) async {
      final repository = FakeLeaderboardRepository(
        pages: {0: _page(testEntries(1, _size)), 1: _page(testEntries(21, 5))},
      );
      await tester.pumpWidget(
        screen(repository, FakeAuthService(user: testUser)),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Rank 25, Player 25, 975 points'),
        300,
      );

      expect(repository.requestedPages, [0, 1]);
    });

    testWidgets('a signed-out player can sign in to see it', (tester) async {
      final repository = FakeLeaderboardRepository(
        pages: {0: APIResult.error(code: 401)},
      );
      await tester.pumpWidget(screen(repository, FakeAuthService()));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to see the leaderboard.'), findsOneWidget);

      repository.pages[0] = _page(testEntries(1, 2));
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Rank 1, Player 1, 999 points'),
        findsOneWidget,
      );
      expect(
        find.text('Solve a puzzle while signed in to join the board.'),
        findsOneWidget,
      );
    });
  });

  group('MyScoreScreen', () {
    testWidgets('shows the totals', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => AuthCubit(FakeAuthService(user: testUser)),
              ),
              BlocProvider(
                create: (_) =>
                    MyScoreCubit(GetMyScoreUseCase(FakeLeaderboardRepository()))
                      ..load(),
              ),
            ],
            child: const MyScoreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Player'), findsOneWidget);
      expect(find.bySemanticsLabel('70 points'), findsOneWidget);
      expect(find.bySemanticsLabel('Puzzles solved: 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Rank: 3'), findsOneWidget);
    });

    for (final size in const [Size(320, 568), Size(412, 915)]) {
      testWidgets('fits a ${size.width}x${size.height} screen', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) => AuthCubit(FakeAuthService(user: testUser)),
                ),
                BlocProvider(
                  create: (_) => MyScoreCubit(
                    GetMyScoreUseCase(FakeLeaderboardRepository()),
                  )..load(),
                ),
              ],
              child: const MyScoreScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
